import 'package:flutter/material.dart';

import '../constants/app_text_styles.dart';

/// A heading that labels the block beneath it, with an optional action opposite.
///
/// The counterpart to `SectionCard`'s built-in header: use that when the title
/// belongs to one card, and this when the title covers whatever follows it —
/// bare fields, a card with no header of its own, or a list of cards.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.trailing});

  final String title;

  /// Sits at the far end of the row, vertically centred against the title.
  /// Typically an `AppTextButton` — Add, Edit, View all.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // Expanded, so a title that wraps once translated pushes the action along
        // rather than colliding with it.
        Expanded(child: Text(title, style: AppTextStyles.h3)),
        ?trailing,
      ],
    );
  }
}
