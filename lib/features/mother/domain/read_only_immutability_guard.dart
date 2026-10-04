import 'package:flutter/foundation.dart';

/// Enforces the Read-Only Immutability Lock (`"ro": 1` / `is_clinical_readonly = true`)
/// on official Ministry of Health (MOH) clinical records imported via Midwife QR sync.
///
/// When [isClinicalReadOnly] is `true`, 100% of edit mutations across
/// Basic Profile, Medical History, Obstetric History, Clinic Visits, and
/// Delivery Plan are blocked on the mother's mobile client to guarantee
/// clinical data integrity and prevent tampering with midwife-verified records.
@immutable
class ReadOnlyImmutabilityGuard {
  const ReadOnlyImmutabilityGuard({
    required this.isClinicalReadOnly,
  });

  /// Creates an active read-only lock (`"ro": 1`).
  const ReadOnlyImmutabilityGuard.locked() : isClinicalReadOnly = true;

  /// Creates an unlocked guard for un-synced local drafts.
  const ReadOnlyImmutabilityGuard.unlocked() : isClinicalReadOnly = false;

  /// Whether the clinical record is locked in read-only mode (`"ro": 1`).
  final bool isClinicalReadOnly;

  /// Alias for [isClinicalReadOnly].
  bool get isLocked => isClinicalReadOnly;

  /// Returns `true` only when the record is unlocked and editable.
  bool canEdit() => !isClinicalReadOnly;

  /// Extracts the `"ro"` (`is_clinical_readonly`) flag from a decoded QR payload map.
  ///
  /// Recognizes:
  /// - `"ro": 1` / `"ro": true` / `"ro": "1"`
  /// - `"is_clinical_readonly": 1` / `"is_clinical_readonly": true`
  /// - `"readOnly": true` / `"readOnly": 1`
  ///
  /// If an explicit `0` or `false` is provided, returns `false`.
  /// Otherwise defaults to [defaultForOfficialSync] (`true` for midwife QR syncs).
  static bool isPayloadReadOnly(
    Map<String, dynamic> jsonMap, {
    bool defaultForOfficialSync = true,
  }) {
    final dynamic rawRo = jsonMap['ro'] ??
        jsonMap['is_clinical_readonly'] ??
        jsonMap['readOnly'] ??
        jsonMap['isClinicalReadOnly'];

    if (rawRo != null) {
      if (rawRo == 1 || rawRo == true) return true;
      if (rawRo == 0 || rawRo == false) return false;
      final String normalized = rawRo.toString().trim().toLowerCase();
      if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
        return true;
      }
      if (normalized == '0' || normalized == 'false' || normalized == 'no') {
        return false;
      }
    }

    return defaultForOfficialSync;
  }

  /// Executes [mutation] only if [canEdit] is `true`.
  /// Returns `null` when [isClinicalReadOnly] is `true` (100% edit lockout).
  T? guardMutation<T>(T Function() mutation) {
    if (isClinicalReadOnly) {
      return null;
    }
    return mutation();
  }

  /// Wraps a [ValueChanged] callback so that it is completely blocked when
  /// [isClinicalReadOnly] is `true`.
  ValueChanged<T>? guardCallback<T>(ValueChanged<T>? callback) {
    if (isClinicalReadOnly || callback == null) {
      return null;
    }
    return (T value) {
      if (!isClinicalReadOnly) {
        callback(value);
      }
    };
  }

  /// Wraps a [VoidCallback] so that it is `null` (disabled) when
  /// [isClinicalReadOnly] is `true`.
  VoidCallback? guardAction(VoidCallback? action) {
    if (isClinicalReadOnly || action == null) {
      return null;
    }
    return () {
      if (!isClinicalReadOnly) {
        action();
      }
    };
  }
}
