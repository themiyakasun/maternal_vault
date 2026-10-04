import 'package:flutter/material.dart';

import '../../features/mother/domain/basic_profile.dart';
import '../../features/mother/domain/clinic_record.dart';
import '../../features/mother/domain/delivery_plan.dart';
import '../../features/mother/domain/epds_screening.dart';
import '../../features/mother/domain/key_vitals.dart';
import '../../features/mother/domain/medical_history.dart';
import '../../features/mother/domain/obstetric_history.dart';
import '../datasources/encrypted_db_helper.dart';
import '../models/clinical_model_evaluator.dart';
import '../models/model_notification.dart';

/// Central Notification System that alerts the mother whenever a clinical AI model
/// identifies elevated risks or produces recommendations.
class ModelNotificationService {
  ModelNotificationService({
    ClinicalModelEvaluator? evaluator,
  }) : _evaluator = evaluator ?? ClinicalModelEvaluator();

  static final ModelNotificationService instance = ModelNotificationService();

  final ClinicalModelEvaluator _evaluator;

  final ValueNotifier<List<ModelNotification>> notificationsNotifier =
      ValueNotifier<List<ModelNotification>>(<ModelNotification>[]);

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  final ValueNotifier<ModelNotification?> latestAlertNotifier =
      ValueNotifier<ModelNotification?>(null);

  final ValueNotifier<List<EpdsScreeningEntry>> moodScreeningsNotifier =
      ValueNotifier<List<EpdsScreeningEntry>>(<EpdsScreeningEntry>[]);

  EpdsScreeningEntry? get latestMoodScreening =>
      moodScreeningsNotifier.value.isNotEmpty
          ? moodScreeningsNotifier.value.first
          : null;

  bool _isInitialized = false;

  bool get _isTestEnvironment {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
    } catch (_) {
      return false;
    }
  }

  /// Loads saved model notifications and EPDS mood logs from the encrypted database.
  Future<void> initialize() async {
    if (_isInitialized || _isTestEnvironment) return;
    try {
      final saved = await EncryptedDatabaseHelper.getModelNotifications()
          .timeout(const Duration(milliseconds: 300));
      notificationsNotifier.value = saved;
      _updateUnreadCount();

      final savedMoods = await EncryptedDatabaseHelper.getMoodScreenings()
          .timeout(const Duration(milliseconds: 300));
      moodScreeningsNotifier.value = savedMoods;

      _isInitialized = true;
    } catch (e) {
      debugPrint('ModelNotificationService init note: $e');
    }
  }

  /// Saves a new 10-item EPDS self-screening & daily symptom entry to the `moods` table.
  Future<void> saveMoodScreening(EpdsScreeningEntry entry) async {
    moodScreeningsNotifier.value = <EpdsScreeningEntry>[
      entry,
      ...moodScreeningsNotifier.value.where((e) => e.id != entry.id),
    ];

    if (!_isTestEnvironment) {
      try {
        await EncryptedDatabaseHelper.saveMoodScreening(entry)
            .timeout(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Failed to persist mood screening to db: $e');
      }
    }
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value =
        notificationsNotifier.value.where((n) => !n.isRead).length;
  }

  /// Posts a new notification generated from an AI/clinical model.
  Future<void> postNotification(
    ModelNotification notification, {
    bool triggerAlert = true,
  }) async {
    // Avoid duplicate alerts within short succession with same model and title
    final existing = notificationsNotifier.value;
    final isDuplicate = existing.any((n) =>
        n.modelType == notification.modelType &&
        n.title == notification.title &&
        n.timestamp.difference(notification.timestamp).inMinutes.abs() < 10);

    if (isDuplicate) return;

    final updated = <ModelNotification>[notification, ...existing];
    notificationsNotifier.value = updated;
    _updateUnreadCount();

    if (triggerAlert && notification.severity.isElevated) {
      latestAlertNotifier.value = notification;
    }

    if (!_isTestEnvironment) {
      try {
        await EncryptedDatabaseHelper.saveModelNotification(notification)
            .timeout(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Failed to persist model notification to db: $e');
      }
    }
  }

  /// Evaluates the mother's latest records with all 3 models in `lib/data/models`
  /// and automatically alerts the mother if any risks are detected.
  /// If [epdsScore], [anxietyScore], [sleepDisturbed], or [reportedFatigue] are not
  /// explicitly supplied, they automatically resolve from the latest saved entry
  /// in the `moods` table ([latestMoodScreening]).
  Future<List<ModelNotification>> evaluateAndAlert({
    required BasicProfile profile,
    required KeyVitals vitals,
    MedicalHistory? history,
    ObstetricHistory? obstetric,
    ClinicRecord? clinic,
    DeliveryPlan? deliveryPlan,
    int? epdsScore,
    int? anxietyScore,
    bool? sleepDisturbed,
    bool? reportedFatigue,
  }) async {
    await initialize();

    final EpdsScreeningEntry? latestMood = latestMoodScreening;
    final int resolvedEpds = epdsScore ?? latestMood?.epdsScore ?? 0;
    final int resolvedAnxiety = anxietyScore ?? latestMood?.anxietyScore ?? 0;
    final bool resolvedSleep =
        sleepDisturbed ?? latestMood?.sleepDisturbed ?? false;
    final bool resolvedFatigue =
        reportedFatigue ?? latestMood?.reportedFatigue ?? false;

    final result = await _evaluator.evaluateAll(
      profile: profile,
      vitals: vitals,
      history: history,
      obstetric: obstetric,
      clinic: clinic,
      deliveryPlan: deliveryPlan,
      epdsScore: resolvedEpds,
      anxietyScore: resolvedAnxiety,
      sleepDisturbed: resolvedSleep,
      reportedFatigue: resolvedFatigue,
      itemResponses: latestMood?.itemResponses,
    );

    for (final alert in result.alerts) {
      await postNotification(alert, triggerAlert: true);
    }

    return result.alerts;
  }

  /// Marks a specific model notification as read.
  Future<void> markAsRead(String id) async {
    final updated = notificationsNotifier.value.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    notificationsNotifier.value = updated;
    _updateUnreadCount();

    if (!_isTestEnvironment) {
      try {
        await EncryptedDatabaseHelper.markModelNotificationAsRead(id)
            .timeout(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Failed to mark notification read in db: $e');
      }
    }
  }

  /// Marks all model notifications as read.
  Future<void> markAllAsRead() async {
    final updated = notificationsNotifier.value.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    notificationsNotifier.value = updated;
    _updateUnreadCount();

    if (!_isTestEnvironment) {
      try {
        await EncryptedDatabaseHelper.markAllModelNotificationsAsRead()
            .timeout(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Failed to mark all notifications read in db: $e');
      }
    }
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String id) async {
    notificationsNotifier.value =
        notificationsNotifier.value.where((n) => n.id != id).toList();
    _updateUnreadCount();

    if (!_isTestEnvironment) {
      try {
        await EncryptedDatabaseHelper.deleteModelNotification(id)
            .timeout(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Failed to delete notification in db: $e');
      }
    }
  }

  /// Clears all model notifications and mood screenings.
  Future<void> clearAll() async {
    notificationsNotifier.value = <ModelNotification>[];
    unreadCountNotifier.value = 0;
    latestAlertNotifier.value = null;
    moodScreeningsNotifier.value = <EpdsScreeningEntry>[];

    if (!_isTestEnvironment) {
      try {
        await EncryptedDatabaseHelper.clearModelNotifications()
            .timeout(const Duration(milliseconds: 300));
        await EncryptedDatabaseHelper.clearMoodScreenings()
            .timeout(const Duration(milliseconds: 300));
      } catch (e) {
        debugPrint('Failed to clear notifications in db: $e');
      }
    }
  }

  /// Alias for [clearAll].
  Future<void> clearAllNotifications() => clearAll();

  void dispose() {
    notificationsNotifier.dispose();
    unreadCountNotifier.dispose();
    latestAlertNotifier.dispose();
    moodScreeningsNotifier.dispose();
    _evaluator.dispose();
  }
}
