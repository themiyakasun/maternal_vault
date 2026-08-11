import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../theme/app_theme.dart';

/// One caption-and-answer pair in a [DetailGrid].
@immutable
class DetailPair {
  const DetailPair({required this.label, this.value});

  final String label;

  /// Null renders an em-dash, so an unrecorded answer reads as unrecorded rather
  /// than as blank space.
  final String? value;
}

/// Read-only counterpart to a form: a grid of captions with their answers.
///
/// Where `LabeledField` puts a caption above something you can change, this puts
/// one above something already decided — the summary of a past pregnancy, a
/// finished clinic visit.
class DetailGrid extends StatelessWidget {
  const DetailGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.rowGap = AppSpacing.componentGap,
    this.columnGap = AppSpacing.componentGap,
  });

  final List<DetailPair> items;

  /// How many pairs sit side by side. Two suits a phone; one is the fallback for
  /// values long enough to wrap.
  final int columns;

  final double rowGap;
  final double columnGap;

  @override
  Widget build(BuildContext context) {
    final List<List<DetailPair>> rows = <List<DetailPair>>[];
    for (int i = 0; i < items.length; i += columns) {
      rows.add(
        items.sublist(i, i + columns > items.length ? items.length : i + columns),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int row = 0; row < rows.length; row++) ...<Widget>[
          if (row > 0) SizedBox(height: rowGap),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int column = 0; column < columns; column++) ...<Widget>[
                if (column > 0) SizedBox(width: columnGap),
                // Every column is claimed even on a short last row, so the
                // columns stay aligned down the grid instead of the final pair
                // spreading across the full width.
                Expanded(
                  child: column < rows[row].length
                      ? _Pair(pair: rows[row][column])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.pair});

  final DetailPair pair;

  @override
  Widget build(BuildContext context) {
    final String? value = pair.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pair.label,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.unit / 2),
        Text(
          value ?? '—',
          style: AppTextStyles.bodyLg.copyWith(
            color: value == null
                ? AppColors.onSurfaceVariant
                : AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
