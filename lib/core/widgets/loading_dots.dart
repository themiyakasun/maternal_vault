import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A row of softly pulsing dots used as an indeterminate loading indicator.
///
/// Each dot rides the same sine wave, offset by [_stagger] per dot, so the
/// motion reads as a gentle left-to-right breath rather than a hard blink.
class LoadingDots extends StatefulWidget {
  const LoadingDots({
    super.key,
    this.color,
    this.dotCount = 3,
    this.dotSize = 10,
    this.spacing = 10,
    this.period = const Duration(milliseconds: 1200),
    this.semanticsLabel,
  });

  /// Defaults to the primary colour of the ambient theme.
  final Color? color;
  final int dotCount;
  final double dotSize;
  final double spacing;

  /// Time for one dot to complete a full fade-in-and-out cycle.
  final Duration period;

  /// Announced to screen readers. Pass null to leave the dots decorative.
  final String? semanticsLabel;

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  static const double _stagger = 0.15;
  static const double _minOpacity = 0.32;
  static const double _minScale = 0.82;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  @override
  void didUpdateWidget(LoadingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.period != oldWidget.period) {
      _controller.duration = widget.period;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.color ?? Theme.of(context).colorScheme.primary;

    final Widget dots = AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (int i = 0; i < widget.dotCount; i++) ...<Widget>[
              if (i > 0) SizedBox(width: widget.spacing),
              _Dot(
                color: color,
                size: widget.dotSize,
                wave: _waveAt(i),
              ),
            ],
          ],
        );
      },
    );

    if (widget.semanticsLabel == null) {
      return ExcludeSemantics(child: dots);
    }
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: ExcludeSemantics(child: dots),
    );
  }

  /// 0 at rest, 1 at the peak of this dot's cycle.
  double _waveAt(int index) {
    final double t = (_controller.value - index * _stagger) % 1.0;
    return math.sin(t * math.pi).clamp(0.0, 1.0);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.size,
    required this.wave,
  });

  final Color color;
  final double size;
  final double wave;

  @override
  Widget build(BuildContext context) {
    final double scale =
        _Dot._lerp(_LoadingDotsState._minScale, 1, wave);
    final double opacity =
        _Dot._lerp(_LoadingDotsState._minOpacity, 1, wave);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
