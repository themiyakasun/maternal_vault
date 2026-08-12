import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../cards/app_card.dart';

/// A titled card holding a chart, with an optional explainer.
///
/// The glyph is the whole reason this exists: a growth curve without a note on
/// what "expected" means is a shape nobody can act on, and that note does not
/// belong on the card where it would be read once and then be in the way.
/// A null [onInfo] draws no glyph rather than a dead one.
class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.onInfo,
    this.infoTooltip,
  });

  final String title;

  /// The chart itself — a `LineChart`, usually.
  final Widget child;

  final VoidCallback? onInfo;

  final String? infoTooltip;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(title, style: AppTextStyles.h3)),
              if (onInfo != null)
                IconButton(
                  onPressed: onInfo,
                  tooltip: infoTooltip,
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.onSurfaceVariant,
                    minimumSize: const Size.square(AppSpacing.minTouchTarget),
                  ),
                  icon: const Icon(Icons.info_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),
          child,
        ],
      ),
    );
  }
}
