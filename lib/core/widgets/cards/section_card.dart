import 'package:flutter/material.dart';

import '../../constants/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'app_card.dart';

/// A titled block of a form: accent glyph, heading, then its fields.
///
/// [accent] is what tells two sections apart at a glance — the rose/sage pairing
/// the app uses everywhere it has two related things to distinguish.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
    this.gap = AppSpacing.componentGap,
  });

  final IconData icon;
  final String title;

  /// Colour identity for the glyph chip.
  final Color accent;

  /// The section's contents, laid out in a column with [gap] between them.
  final List<Widget> children;

  /// Vertical space between [children]. Inserted by the card so callers do not
  /// have to thread a [SizedBox] between every field.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.md),
                  ),
                ),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: AppSpacing.stackMd),
              // Titles run long once translated, so the heading wraps rather
              // than being clipped or pushing the glyph off the card.
              Expanded(child: Text(title, style: AppTextStyles.h3)),
            ],
          ),
          for (final Widget child in children) ...<Widget>[
            SizedBox(height: gap),
            child,
          ],
        ],
      ),
    );
  }
}
