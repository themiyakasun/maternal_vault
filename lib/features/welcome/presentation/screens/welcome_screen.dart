import 'package:flutter/material.dart';

import '../../../../core/l10n/app_locales.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_backdrop.dart';
import '../../domain/user_role.dart';
import '../steps/about_step.dart';
import '../steps/language_step.dart';
import '../steps/role_step.dart';
import '../widgets/welcome_header.dart';
import '../widgets/welcome_nav_bar.dart';

/// The three-screen onboarding: language, about the app, role — sharing one
/// header lockup, one Back/Next bar, and one gradient backdrop.
///
/// Pushes this flow as a replacement page from the splash rather than showing
/// it as [home], so the splash keeps its entrance animation in the same route
/// and back-gesture exits the app instead of returning to a re-animating
/// splash.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.onLanguageChanged,
    this.onCompleted,
  });

  /// Asks the app root to switch languages. The flow never reads back a stored
  /// copy of the answer — see [_WelcomeScreenState._buildStep].
  final ValueChanged<AppLanguage> onLanguageChanged;

  /// Called with the chosen role when the user finishes the flow.
  final ValueChanged<UserRole>? onCompleted;

  /// The splash hands over with a route replacement so the back gesture leaves
  /// the app.
  static Route<void> route({
    required ValueChanged<AppLanguage> onLanguageChanged,
    ValueChanged<UserRole>? onCompleted,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (BuildContext context, _, _) => WelcomeScreen(
        onLanguageChanged: onLanguageChanged,
        onCompleted: onCompleted,
      ),
      transitionsBuilder:
          (BuildContext context, Animation<double> animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _stepIndex = 0;
  UserRole? _role;

  static const int _stepCount = 3;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: AppSpacing.stackLg),
                WelcomeHeader(compact: compact),
                const SizedBox(height: AppSpacing.stackLg),
                Expanded(
                  // Keys let AnimatedSwitcher distinguish the three steps, so
                  // it cross-fades instead of rebuilding in place.
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildStep(compact),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                WelcomeNavBar(
                  stepCount: _stepCount,
                  currentIndex: _stepIndex,
                  onNext: _canAdvance ? _advance : null,
                  onBack: _stepIndex == 0 ? null : _goBack,
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool compact) {
    switch (_stepIndex) {
      case 0:
        // Read the selection straight off the live locale instead of a stored
        // copy. The locale *does* update when a tile is tapped (MaterialApp
        // re-renders every localized string in it) — but passing the value
        // along as a field would freeze it at the value from the moment the
        // flow was pushed, so the checkmark would never move.
        return LanguageStep(
          key: const ValueKey<int>(0),
          selected: AppLanguage.fromLocale(
            Localizations.maybeLocaleOf(context),
          ),
          onSelected: widget.onLanguageChanged,
          compact: compact,
        );
      case 1:
        return AboutStep(
          key: const ValueKey<int>(1),
          compact: compact,
        );
      case 2:
        return RoleStep(
          key: const ValueKey<int>(2),
          selected: _role,
          onSelected: (UserRole role) => setState(() => _role = role),
          compact: compact,
        );
      default:
        throw StateError('Unknown welcome step $_stepIndex');
    }
  }

  /// The flow can advance only once a selection exists on the current step.
  bool get _canAdvance {
    switch (_stepIndex) {
      case 0:
        return true; // English is pre-selected, so there is always a choice.
      case 1:
        return true;
      case 2:
        return _role != null;
      default:
        return false;
    }
  }

  void _advance() {
    if (_stepIndex == _stepCount - 1) {
      widget.onCompleted?.call(_role!);
      return;
    }
    setState(() => _stepIndex++);
  }

  void _goBack() => setState(() => _stepIndex--);
}
