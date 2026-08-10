import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The standard full-screen page backdrop: the rose page gradient.
///
/// Screen scaffolds that sit on the tinted surface should wrap their body in
/// this instead of re-stating the gradient, so the wash stays in one place when
/// it changes.
class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: child,
    );
  }
}
