import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons/app_button_tone.dart';
import '../../../../core/widgets/buttons/app_outline_button.dart';
import '../../../../core/widgets/buttons/app_primary_button.dart';
import '../../../../data/models/model_notification.dart';

/// Modal dialog displayed to immediately alert the mother when an AI/clinical model
/// triggers an elevated risk or urgent notification.
class ModelAlertDialog extends StatelessWidget {
  const ModelAlertDialog({
    super.key,
    required this.notification,
    this.onViewAll,
    this.onDismiss,
  });

  final ModelNotification notification;
  final VoidCallback? onViewAll;
  final VoidCallback? onDismiss;

  static Future<void> show(
    BuildContext context,
    ModelNotification notification, {
    VoidCallback? onViewAll,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => ModelAlertDialog(
        notification: notification,
        onViewAll: () {
          Navigator.of(dialogContext).pop();
          onViewAll?.call();
        },
        onDismiss: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return AppColors.secondary;
      case AlertSeverity.moderate:
        return const Color(0xFFD97706); // Warm Amber
      case AlertSeverity.high:
      case AlertSeverity.critical:
        return AppColors.error;
    }
  }

  IconData _modelIcon(ModelType type) {
    switch (type) {
      case ModelType.maternalRisk:
        return Icons.favorite_rounded;
      case ModelType.pretermRisk:
        return Icons.child_care_rounded;
      case ModelType.mentalHealth:
        return Icons.psychology_rounded;
      case ModelType.clinicalSync:
        return Icons.sync_problem_rounded;
      case ModelType.general:
        return Icons.notification_important_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(notification.severity);

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.cardRadius,
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _modelIcon(notification.modelType),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    notification.severity.label.toUpperCase(),
                    style: AppTextStyles.labelCaps.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.modelName,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              notification.title,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.onSurface,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              notification.message,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (notification.recommendations.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.stackMd),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CLINICAL RECOMMENDATIONS',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final rec in notification.recommendations) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                rec,
                                style: AppTextStyles.bodySm.copyWith(
                                  fontSize: 12,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Generated automatically by Maternal Vault AI clinical models from your encrypted record.',
              style: AppTextStyles.labelCaps.copyWith(
                fontSize: 10,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: <Widget>[
        if (onViewAll != null)
          AppOutlineButton(
            label: 'All Alerts',
            onPressed: onViewAll,
          ),
        AppPrimaryButton(
          label: 'Acknowledge',
          tone: AppButtonTone.primary,
          onPressed: onDismiss ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
