import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../data/models/model_notification.dart';
import '../../../../data/services/model_notification_service.dart';
import '../../domain/basic_profile.dart';
import '../../domain/clinic_record.dart';
import '../../domain/epds_screening.dart';
import '../../domain/key_vitals.dart';
import '../../domain/medical_history.dart';
import '../../domain/obstetric_history.dart';
import '../widgets/model_alert_dialog.dart';

/// Screen allowing the Expectant Mother to complete the 10-item Edinburgh
/// Postnatal Depression Scale (EPDS) self-screening questionnaire and log
/// daily moods and symptoms, persisted in the `moods` SQLCipher table and
/// evaluated on-device by `MentalHealthModel` (`mental_health_int8.tflite`).
class EpdsScreeningScreen extends StatefulWidget {
  const EpdsScreeningScreen({
    super.key,
    this.profile,
    this.vitals,
    this.history,
    this.obstetric,
    this.clinic,
  });

  final BasicProfile? profile;
  final KeyVitals? vitals;
  final MedicalHistory? history;
  final ObstetricHistory? obstetric;
  final ClinicRecord? clinic;

  static Route<EpdsScreeningEntry?> route({
    BasicProfile? profile,
    KeyVitals? vitals,
    MedicalHistory? history,
    ObstetricHistory? obstetric,
    ClinicRecord? clinic,
  }) {
    return MaterialPageRoute<EpdsScreeningEntry?>(
      builder: (BuildContext context) => EpdsScreeningScreen(
        profile: profile,
        vitals: vitals,
        history: history,
        obstetric: obstetric,
        clinic: clinic,
      ),
    );
  }

  @override
  State<EpdsScreeningScreen> createState() => _EpdsScreeningScreenState();
}

class _EpdsScreeningScreenState extends State<EpdsScreeningScreen> {
  final List<int> _responses = List<int>.filled(10, 0);
  String _selectedMood = kDailyMoodOptions.first;
  final Set<String> _selectedSymptoms = <String>{};
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    ModelNotificationService.instance.initialize();
    final EpdsScreeningEntry? latest =
        ModelNotificationService.instance.latestMoodScreening;
    if (latest != null && latest.itemResponses.length == 10) {
      for (int i = 0; i < 10; i++) {
        _responses[i] = latest.itemResponses[i].clamp(0, 3);
      }
      _selectedMood = latest.dailyMood;
      _selectedSymptoms.addAll(latest.dailySymptoms);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalEpdsScore =>
      _responses.fold<int>(0, (int sum, int item) => sum + item);

  int get _anxietySubscore =>
      _responses[2] + _responses[3] + _responses[4];

  bool get _sleepDisturbed =>
      _responses[6] >= 2 ||
      _selectedSymptoms.contains('Difficulty Sleeping');

  bool get _reportedFatigue =>
      _responses[5] >= 2 ||
      _selectedMood == 'Tired' ||
      _selectedSymptoms.contains('Persistent Fatigue');

  Color _scoreBadgeColor(int score) {
    if (score >= 13 || _responses[9] >= 1) return AppColors.error;
    if (score >= 10) return const Color(0xFFD97706);
    return AppColors.secondary;
  }

  String _scoreCategoryText(int score) {
    if (score >= 13 || _responses[9] >= 1) {
      return 'Elevated Risk (EPDS ≥ 13)';
    }
    if (score >= 10) {
      return 'Moderate Strain (EPDS 10–12)';
    }
    return 'Low Risk (EPDS 0–9)';
  }

  Future<void> _submitScreening() async {
    setState(() => _isSubmitting = true);
    try {
      final EpdsScreeningEntry entry = EpdsScreeningEntry(
        itemResponses: List<int>.from(_responses),
        epdsScore: _totalEpdsScore,
        anxietyScore: _anxietySubscore,
        sleepDisturbed: _sleepDisturbed,
        reportedFatigue: _reportedFatigue,
        dailyMood: _selectedMood,
        dailySymptoms: _selectedSymptoms.toList(),
        notes: _notesController.text.trim(),
      );

      final ModelNotificationService service =
          ModelNotificationService.instance;
      await service.saveMoodScreening(entry);

      final List<ModelNotification> alerts = await service.evaluateAndAlert(
        profile: widget.profile ?? const BasicProfile.empty(),
        vitals: widget.vitals ?? const KeyVitals.empty(),
        history: widget.history,
        obstetric: widget.obstetric,
        clinic: widget.clinic,
        epdsScore: entry.epdsScore,
        anxietyScore: entry.anxietyScore,
        sleepDisturbed: entry.sleepDisturbed,
        reportedFatigue: entry.reportedFatigue,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final ModelNotification? mentalAlert = alerts
          .where((ModelNotification a) => a.modelType == ModelType.mentalHealth)
          .firstOrNull;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'EPDS Self-Screening (${entry.epdsScore}/30) & Daily Mood saved to encrypted vault.',
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );

      if (mentalAlert != null && mounted) {
        await ModelAlertDialog.show(context, mentalAlert);
      }
    } finally {
      if (mounted && _isSubmitting) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int score = _totalEpdsScore;
    final Color badgeColor = _scoreBadgeColor(score);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('EPDS & Daily Wellbeing Log'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.stackSm,
        ),
        children: <Widget>[
          // Live Score Summary Header Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.self_improvement_rounded,
                        color: badgeColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Perinatal Mental Health Check',
                            style: AppTextStyles.h3.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '10-Item Edinburgh Postnatal Depression Scale (EPDS) & Daily Log',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '$score / 30',
                        key: const Key('epds_total_score_badge'),
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetricChip(
                      label: _scoreCategoryText(score),
                      color: badgeColor,
                    ),
                    _MetricChip(
                      label: 'Anxiety Subscale: $_anxietySubscore / 9',
                      color: AppColors.primary,
                    ),
                    _MetricChip(
                      label: 'Mood: $_selectedMood',
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // SECTION 1: DAILY MOOD & SYMPTOM LOGGING
          Text(
            'DAILY MOOD & SYMPTOM LOG',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'How is your mood today?',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kDailyMoodOptions.map((String mood) {
                    final bool isSelected = _selectedMood == mood;
                    return ChoiceChip(
                      label: Text(mood),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() => _selectedMood = mood);
                        }
                      },
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: AppTextStyles.bodySm.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurface,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Any daily physical or sleep symptoms?',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kDailySymptomOptions.map((String symptom) {
                    final bool isSelected =
                        _selectedSymptoms.contains(symptom);
                    return FilterChip(
                      label: Text(symptom),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedSymptoms.add(symptom);
                          } else {
                            _selectedSymptoms.remove(symptom);
                          }
                        });
                      },
                      selectedColor:
                          AppColors.secondaryContainer.withValues(alpha: 0.7),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Personal reflection or symptom notes (optional)',
                    hintText: 'E.g., Woke up twice last night, feeling a bit tired...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // SECTION 2: 10-ITEM EPDS QUESTIONNAIRE
          Text(
            '10-ITEM EPDS SELF-SCREENING (PAST 7 DAYS)',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Please select the answer that comes closest to how you have felt in the past 7 days.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          for (int qIdx = 0; qIdx < kEpdsQuestions.length; qIdx++) ...<Widget>[
            _buildQuestionCard(qIdx, kEpdsQuestions[qIdx]),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('submit_epds_screening_button'),
              onPressed: _isSubmitting ? null : _submitScreening,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.psychology_rounded),
              label: Text(
                _isSubmitting
                    ? 'Saving & Evaluating...'
                    : 'Save & Run Mental Health AI Check',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sectionGap),

          // SECTION 3: PAST SCREENING HISTORY
          ValueListenableBuilder<List<EpdsScreeningEntry>>(
            valueListenable:
                ModelNotificationService.instance.moodScreeningsNotifier,
            builder: (
              BuildContext context,
              List<EpdsScreeningEntry> history,
              _,
            ) {
              if (history.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'RECENT MOOD & EPDS LOGS (${history.length})',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final EpdsScreeningEntry item in history.take(5)) ...<Widget>[
                    AppCard(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.favorite_rounded,
                            color: _scoreBadgeColor(item.epdsScore),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Mood: ${item.dailyMood} • EPDS: ${item.epdsScore}/30',
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(item.createdAt),
                                  style: AppTextStyles.bodySm.copyWith(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                if (item.dailySymptoms.isNotEmpty)
                                  Text(
                                    'Symptoms: ${item.dailySymptoms.join(', ')}',
                                    style: AppTextStyles.bodySm.copyWith(
                                      fontSize: 12,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _scoreBadgeColor(item.epdsScore)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.riskCategory,
                              style: AppTextStyles.labelCaps.copyWith(
                                color: _scoreBadgeColor(item.epdsScore),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int qIdx, EpdsQuestion item) {
    final int selectedScore = _responses[qIdx];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.question,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          for (int optIdx = 0; optIdx < item.options.length; optIdx++)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _responses[qIdx] = optIdx;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      selectedScore == optIdx
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 20,
                      color: selectedScore == optIdx
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.options[optIdx],
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: selectedScore == optIdx
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: selectedScore == optIdx
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
