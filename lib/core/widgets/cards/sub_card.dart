import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'app_card.dart';

/// A titled block nested inside a [SectionCard] — the two parents' details on
/// the profile form, and anything else that groups a few fields under a subject
/// without being a section of its own.
///
/// Flat rather than lifted: a shadow inside a card reads as a stacking mistake,
/// so this one carries a faint accent wash and a hairline instead.
class SubCard extends StatelessWidget {
  const SubCard({
    super.key,
    required this.title,
    required this.accent,
    required this.children,
    this.gap = AppSpacing.componentGap,
  });

  final String title;

  /// Colour identity, applied as a wash behind the block.
  final Color accent;

  /// The block's contents, laid out in a column with [gap] between them.
  final List<Widget> children;

  final double gap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: accent.withValues(alpha: 0.04),
      borderColor: AppColors.outlineVariant,
      boxShadow: const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600),
          ),
          const Divider(),
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
