import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_dots.dart';
import '../widgets/animated_logo.dart';
import '../widgets/brand_wordmark.dart';

/// Branded launch screen.
///
/// Runs a short staggered entrance — logo, then wordmark, then tagline — over a
/// faded illustration, while the app does its startup work. When [onComplete]
/// is provided the screen calls it once both the animation and [initialization]
/// have finished, so navigation never cuts the motion short.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onComplete,
    this.initialization,
    this.minimumDuration = const Duration(milliseconds: 2600),
  });

  /// Invoked once the splash is done. Typically navigates onward.
  final VoidCallback? onComplete;

  /// Startup work to await — loading session state, warming caches, and so on.
  /// The splash stays up until this completes, even past [minimumDuration].
  final Future<void>? initialization;

  /// How long the splash stays up at minimum, so the brand never just flickers.
  final Duration minimumDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// Drives the one-shot entrance stagger.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// Drives the logo's looping halo.
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  late final Animation<double> _logoEntrance = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
  );

  late final Animation<double> _wordmarkFade = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
  );

  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
  );

  late final Animation<double> _dotsFade = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
  );

  late final Animation<double> _backgroundFade = CurvedAnimation(
    parent: _entranceController,
    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _entranceController.forward();
    _pulseController.repeat();
    _runStartupSequence();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Holds the splash for [SplashScreen.minimumDuration] and for whatever
  /// startup work was handed to us, whichever finishes last.
  Future<void> _runStartupSequence() async {
    await Future.wait<void>(<Future<void>>[
      Future<void>.delayed(widget.minimumDuration),
      if (widget.initialization != null) widget.initialization!,
    ]);

    if (!mounted || _completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool isCompact = screen.height < 700;
    final double logoSize = isCompact ? 148.0 : 180.0;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFFDF4F6),
              AppColors.surfaceContainerLowest,
              Color(0xFFFDF6F3),
            ],
            stops: <double>[0, 0.55, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildBackdrop(),
            _buildForeground(logoSize, isCompact),
          ],
        ),
      ),
    );
  }

  /// The illustration, held far back so the mark and type stay legible.
  ///
  /// Full-bleed: the square source is scaled until it fills the height, with
  /// the surplus width overflowing past both edges. `contain` would letterbox
  /// it to a small square and `fill` would squeeze the figure narrow, so
  /// neither keeps the proportions of the design.
  Widget _buildBackdrop() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: _backgroundFade,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double h = constraints.maxHeight;
            final double w = h; // square aspect, matching the source image
            return ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: <double>[0.0, 0.14, 0.82, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: OverflowBox(
                alignment: Alignment.center,
                maxWidth: w,
                minHeight: h,
                maxHeight: h,
                child: Opacity(
                  opacity: 0.55,
                  child: Image.asset(
                    'assets/images/splash_illustration.png',
                    width: w,
                    height: h,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForeground(double logoSize, bool isCompact) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          children: <Widget>[
            const Spacer(flex: 5),
            AnimatedLogo(
              entrance: _logoEntrance,
              pulse: _pulseController,
              size: logoSize,
            ),
            SizedBox(
              height: isCompact ? AppSpacing.stackSm : AppSpacing.stackMd,
            ),
            _SlideFade(
              animation: _wordmarkFade,
              child: BrandWordmark(fontSize: isCompact ? 34 : 40),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            _SlideFade(
              animation: _taglineFade,
              child: Text(
                AppStrings.appTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const Spacer(flex: 4),
            FadeTransition(
              opacity: _dotsFade,
              child: const LoadingDots(
                color: AppColors.primaryContainer,
                dotSize: 11,
                spacing: 11,
                semanticsLabel: AppStrings.loading,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
          ],
        ),
      ),
    );
  }
}

/// Fades a child in while lifting it a few pixels — the standard entrance for
/// the splash's text layers.
class _SlideFade extends StatelessWidget {
  const _SlideFade({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
