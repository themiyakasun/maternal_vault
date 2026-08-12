import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A round avatar that degrades honestly: a photo when one is supplied, a glyph
/// on a tinted disc when one is not — never a stand-in face.
///
/// The partner header wants a small profile picture, but no photo ships with
/// the app yet. Rather than draw a portrait for someone who has none, [image] is
/// optional and the fallback is plainly an icon, so an empty avatar reads as "no
/// picture" instead of "some person".
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.image,
    this.icon = Icons.person_rounded,
    this.size = 36,
    this.background,
    this.foreground,
  });

  /// The picture to show. Null falls back to [icon].
  final ImageProvider<Object>? image;

  /// Shown when there is no [image].
  final IconData icon;

  final double size;

  /// Disc colour behind the fallback glyph. Defaults to a soft rose tint.
  final Color? background;

  /// Fallback glyph colour. Defaults to the rose the tint is drawn from.
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? picture = image;
    if (picture != null) {
      return ClipOval(
        child: Image(
          image: picture,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final Color tint = background ?? AppColors.primary.withValues(alpha: 0.12);
    final Color glyph = foreground ?? AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.58, color: glyph),
    );
  }
}
