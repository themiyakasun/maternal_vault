import 'package:flutter/material.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cards/app_card.dart';
import '../../../../core/widgets/detail_grid.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/clinic_record.dart';
import 'clinic_labels.dart';

/// One routine visit, sized to sit in the horizontal strip on the clinic tab.
///
/// A fixed width rather than the page width: the strip is scanned sideways to
/// compare this visit against the last, which only works if the next card is
/// visibly there to be scrolled to.
class ClinicVisitCard extends StatelessWidget {
  const ClinicVisitCard({super.key, required this.visit, this.width = 268});

  final ClinicVisit visit;

  final double width;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MaterialLocalizations material = MaterialLocalizations.of(context);

    return SizedBox(
      width: width,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    // "OCT 12, 2023" — assembled from the framework's own month
                    // and year formatters so it follows the locale without this
                    // app carrying date patterns of its own.
                    '${material.formatShortMonthDay(visit.date)}, '
                            '${material.formatYear(visit.date)}'
                        .toUpperCase(),
                    style: AppTextStyles.labelCaps,
                  ),
                ),
                const SizedBox(width: AppSpacing.stackSm),
                StatusChip(
                  label: visitStatusLabel(l10n, visit.status),
                  accent: visitStatusAccent(visit.status),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.unit / 2),
            Text(l10n.visitWeek(visit.week), style: AppTextStyles.h2),
            const SizedBox(height: AppSpacing.stackMd),
            DetailGrid(
              items: <DetailPair>[
                DetailPair(label: l10n.fieldBp, value: visit.bloodPressure),
                DetailPair(
                  label: l10n.fieldWeight,
                  value: visit.weightKg == null
                      ? null
                      : '${_trim(visit.weightKg!)} ${l10n.unitKilograms}',
                ),
                DetailPair(
                  label: l10n.fieldFundalHeight,
                  value: visit.fundalHeightCm == null
                      ? null
                      : '${visit.fundalHeightCm} ${l10n.unitCentimetres}',
                ),
                DetailPair(
                  label: l10n.fieldFhs,
                  value: visit.fetalHeartRate == null
                      ? null
                      : '${visit.fetalHeartRate} ${l10n.unitBpm}',
                ),
              ],
            ),
            const Divider(),
            DetailGrid(
              columns: 1,
              items: <DetailPair>[
                DetailPair(label: l10n.fieldUrine, value: _urine(l10n)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "S: Nil, A: Trace" — or whichever half was taken, or null for neither.
  String? _urine(AppLocalizations l10n) {
    final UrineReading? sugar = visit.urineSugar;
    final UrineReading? albumin = visit.urineAlbumin;

    final String? sugarText = sugar == null
        ? null
        : l10n.urineSugarShort(urineLabel(l10n, sugar));
    final String? albuminText = albumin == null
        ? null
        : l10n.urineAlbuminShort(urineLabel(l10n, albumin));

    if (sugarText != null && albuminText != null) {
      return '$sugarText, $albuminText';
    }
    return sugarText ?? albuminText;
  }

  /// Drops a trailing `.0`, so a round 68 kg does not read as a precision the
  /// scale did not give.
  String _trim(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}
