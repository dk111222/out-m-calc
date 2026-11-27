import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../app/platform_auth.dart';
import '../app/providers.dart';
import '../l10n/copy.dart';
import '../ui/login_style.dart';

/// Parent sign-in for a children's math app.
///
/// Google and Apple use their official marks and button colors.
/// Guest play stays on this device and does not collect a child's
/// personal information. Copy on this page is simple English for a parent.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage>
    with SingleTickerProviderStateMixin {
  String? _error;
  String? _busy;
  late final AnimationController _enter;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: LoginStyle.enterDuration,
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.isAnimating || _enter.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: LoginStyle.background,
        systemNavigationBarColor: LoginStyle.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: LoginStyle.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Semantics(
            namesRoute: true,
            label: 'Sign in',
            explicitChildNodes: true,
            child: FadeTransition(
              opacity: _fade,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LoginStyle.pageHorizontal,
                        vertical: LoginStyle.pageVertical,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: LoginStyle.contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(platform),
                              const Spacer(),
                              _actions(platform),
                              if (_error != null) ...[
                                const SizedBox(height: LoginStyle.afterActions),
                                _errorText(platform),
                              ],
                              const Spacer(),
                              _legal(platform),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(TargetPlatform platform) {
    return Column(
      children: [
        const _MathMark(),
        const SizedBox(height: LoginStyle.logoToName),
        Text(
          'StepMath',
          textAlign: TextAlign.center,
          style: LoginStyle.title(platform),
        ),
        const SizedBox(height: LoginStyle.nameToHeadline),
        Text(
          "Let's practice math!",
          textAlign: TextAlign.center,
          style: LoginStyle.headline(platform),
        ),
        const SizedBox(height: LoginStyle.headlineToSubtitle),
        Text(
          'For parents: guest play stays on this device. We do not '
          'collect your child\'s name, email, or other personal '
          'information in guest mode.',
          textAlign: TextAlign.center,
          style: LoginStyle.subtitle(platform),
        ),
      ],
    );
  }

  Widget _actions(TargetPlatform platform) {
    final locked = _busy != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LoginButton(
          label: 'Continue with Google',
          busy: _busy == 'google',
          onPressed: locked ? null : _signInWithGoogle,
          background: LoginStyle.googleFill,
          foreground: LoginStyle.googleText,
          borderColor: LoginStyle.googleStroke,
          leading: const _GoogleLogo(),
        ),
        const SizedBox(height: LoginStyle.buttonGap),
        _LoginButton(
          label: 'Continue with Apple',
          busy: _busy == 'apple',
          onPressed: locked ? null : _signInWithApple,
          background: LoginStyle.appleFill,
          foreground: LoginStyle.appleText,
          leading: const SizedBox(
            width: 18,
            height: 22,
            child: CustomPaint(
              painter: AppleLogoPainter(color: LoginStyle.appleText),
            ),
          ),
        ),
        const SizedBox(height: LoginStyle.buttonGap),
        _orDivider(platform),
        const SizedBox(height: LoginStyle.buttonGap),
        _LoginButton(
          label: 'Play as Guest',
          busy: _busy == 'guest',
          onPressed: locked ? null : _signInAsGuest,
          background: LoginStyle.guestFill,
          foreground: LoginStyle.accentText,
          borderColor: LoginStyle.accent,
        ),
      ],
    );
  }

  Widget _orDivider(TargetPlatform platform) {
    return Row(
      children: [
        const Expanded(child: Divider(color: LoginStyle.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: LoginStyle.dividerLabel(platform)),
        ),
        const Expanded(child: Divider(color: LoginStyle.divider, height: 1)),
      ],
    );
  }

  Widget _errorText(TargetPlatform platform) {
    return Semantics(
      liveRegion: true,
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: LoginStyle.error(platform),
      ),
    );
  }

  Widget _legal(TargetPlatform platform) {
    final style = TextButton.styleFrom(
      foregroundColor: LoginStyle.accentText,
      minimumSize: const Size(LoginStyle.minTarget, LoginStyle.minTarget),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: LoginStyle.legal(platform),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          style: style,
          onPressed: _busy == null
              ? () => context.go('/settings/privacy?from=sign-in')
              : null,
          child: const Text('Privacy Policy'),
        ),
        Text('|', style: LoginStyle.dividerLabel(platform)),
        TextButton(
          style: style,
          onPressed: _busy == null
              ? () => context.go('/terms?from=sign-in')
              : null,
          child: const Text('Terms of Service'),
        ),
      ],
    );
  }

  /// Google sign-in.
  ///
  /// Opens the Google account sheet. The account is used only to recognize
  /// the parent on this device. Cancel and platform failures stay on this page.
  Future<void> _signInWithGoogle() {
    return _runProvider('google', signInWithGoogle);
  }

  /// Apple sign-in.
  ///
  /// Opens Sign in with Apple. The Apple ID is used only to recognize the
  /// parent on this device. A canceled sheet is told in plain language.
  Future<void> _signInWithApple() {
    return _runProvider('apple', signInWithApple);
  }

  /// Anonymous guest sign-in.
  ///
  /// Keeps a guest identity on this device only. No name, email, or
  /// advertising id is uploaded. Firebase anonymous auth is not used:
  /// that call would send an identifier off the device, which does not
  /// match the guest-mode promise shown to parents.
  Future<void> _signInAsGuest() async {
    final app = ref.read(appProvider);
    setState(() {
      _busy = 'guest';
      _error = null;
    });
    try {
      final error = await app.signInAsGuest();
      if (!mounted) return;
      if (error != null) {
        _showError(error);
        return;
      }
      context.go(app.homeLocation());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _error = 'Sign-in did not finish. Please try again.';
      });
    }
  }

  Future<void> _runProvider(
    String provider,
    Future<ParentIdentity?> Function() request,
  ) async {
    final app = ref.read(appProvider);
    setState(() {
      _busy = provider;
      _error = null;
    });
    try {
      final identity = await request();
      if (!mounted) return;
      if (identity == null) {
        setState(() {
          _busy = null;
          _error = 'Sign-in was canceled.';
        });
        return;
      }
      final error = await app.signInWithIdentity(
        provider: identity.provider,
        subject: identity.subject,
        email: identity.email,
        name: identity.name,
      );
      if (!mounted) return;
      if (error != null) {
        _showError(error);
        return;
      }
      context.go(app.homeLocation());
    } on SignInWithAppleAuthorizationException catch (error) {
      if (!mounted) return;
      final canceled = error.code == AuthorizationErrorCode.canceled;
      setState(() {
        _busy = null;
        _error = canceled
            ? 'Sign-in was canceled.'
            : 'Sign-in did not finish. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _error = 'Sign-in did not finish. Please try again.';
      });
    }
  }

  void _showError(String error) {
    setState(() {
      _busy = null;
      _error = _englishError(error);
    });
  }

  String _englishError(String error) {
    const zh = Copy('zh');
    const en = Copy('en');
    if (error == zh.accountAlreadyOnDevice ||
        error == en.accountAlreadyOnDevice) {
      return 'This device already has an account. '
          'A parent can delete it in Settings, then try again.';
    }
    if (error == zh.couldNotSave || error == en.couldNotSave) {
      return 'We could not save the sign-in. Please try again.';
    }
    return 'Sign-in did not finish. Please try again.';
  }
}

class _MathMark extends StatelessWidget {
  const _MathMark();

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return ExcludeSemantics(
      child: Container(
        width: LoginStyle.logoBox,
        height: LoginStyle.logoBox,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LoginStyle.accentSoft,
          borderRadius: BorderRadius.circular(LoginStyle.logoRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _block('2', LoginStyle.accent, platform),
            const SizedBox(width: LoginStyle.blockGap),
            _block('+', LoginStyle.warning, platform),
            const SizedBox(width: LoginStyle.blockGap),
            _block('3', LoginStyle.success, platform),
          ],
        ),
      ),
    );
  }

  Widget _block(String label, Color edge, TargetPlatform platform) {
    return Container(
      width: 26,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LoginStyle.guestFill,
        borderRadius: BorderRadius.circular(LoginStyle.blockRadius),
        border: Border.all(color: edge, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: LoginStyle.fontFamily(platform),
          fontSize: 16,
          height: 1,
          fontWeight: FontWeight.w700,
          color: LoginStyle.textMain,
        ),
      ),
    );
  }
}

/// Official four-color Google G. Colors stay on the brand values.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final stroke = side * 0.2;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      side - stroke,
      side - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Clockwise from the upper left: red, blue, green, yellow.
    paint.color = LoginStyle.googleRed;
    canvas.drawArc(rect, _rad(200), _rad(130), false, paint);
    paint.color = LoginStyle.googleBlue;
    canvas.drawArc(rect, _rad(330), _rad(80), false, paint);
    paint.color = LoginStyle.googleGreen;
    canvas.drawArc(rect, _rad(50), _rad(80), false, paint);
    paint.color = LoginStyle.googleYellow;
    canvas.drawArc(rect, _rad(130), _rad(70), false, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = LoginStyle.googleBlue;
    canvas.drawRect(
      Rect.fromLTWH(side * 0.46, side * 0.40, side * 0.50, stroke),
      paint,
    );
  }

  double _rad(double degrees) => degrees * 3.141592653589793 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LoginButton extends StatefulWidget {
  const _LoginButton({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.leading,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final Widget? leading;
  final bool busy;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final enabled = widget.onPressed != null && !widget.busy;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final border = widget.borderColor ?? Colors.transparent;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: Focus(
        child: AnimatedScale(
          scale: _pressed && enabled && !reduce ? LoginStyle.pressScale : 1,
          duration: reduce ? Duration.zero : LoginStyle.pressDuration,
          curve: Curves.easeOut,
          alignment: Alignment.center,
          child: Material(
            color: widget.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LoginStyle.radius),
              side: BorderSide(color: border, width: LoginStyle.borderWidth),
            ),
            child: InkWell(
              onTap: enabled ? widget.onPressed : null,
              onHighlightChanged: (pressed) {
                if (_pressed == pressed) return;
                setState(() => _pressed = pressed);
              },
              borderRadius: BorderRadius.circular(LoginStyle.radius),
              focusColor: LoginStyle.accent.withValues(alpha: 0.16),
              child: SizedBox(
                height: LoginStyle.buttonHeight,
                width: double.infinity,
                child: Opacity(
                  opacity: widget.onPressed == null && !widget.busy ? 0.55 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: LoginStyle.brandSlot,
                          height: LoginStyle.brandSlot,
                          child: Center(child: _leading()),
                        ),
                        Expanded(
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            style: LoginStyle.button(platform, widget.foreground),
                          ),
                        ),
                        const SizedBox(width: LoginStyle.brandSlot),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _leading() {
    if (widget.busy) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.foreground,
        ),
      );
    }
    return widget.leading ?? const SizedBox.shrink();
  }
}
