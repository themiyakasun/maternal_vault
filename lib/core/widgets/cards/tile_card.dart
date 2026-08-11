import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'app_card.dart';

/// A card that is nothing but a run of rows — switches, checkboxes, links.
///
/// `SectionCard` with no header, for when the heading sits on the page above the
/// card instead of inside it (see `SectionHeading`). Rules between the rows are
/// the default here rather than the exception: a headerless card is a list, and a
/// list of five near-identical rows is hard to scan unbroken.
class TileCard extends StatelessWidget {
  const TileCard({
    super.key,
    required this.children,
    this.divided = true,
    this.gap = AppSpacing.componentGap,
  });

  /// The rows, in order.
  final List<Widget> children;

  /// Draws a hairline between rows. False falls back to [gap] of plain space.
  final bool divided;

  /// Vertical space between rows when [divided] is false.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) divided ? const Divider() : SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
