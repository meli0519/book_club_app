import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/email_password_form.dart';
import '../../widgets/common/alchemical_background.dart';
import '../../widgets/common/alquimia_logo.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AlchemicalBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SingleChildScrollView(
                child: _AnimatedAuthContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Orchestrates staggered entrance animations for all auth content.
class _AnimatedAuthContent extends StatefulWidget {
  @override
  State<_AnimatedAuthContent> createState() => _AnimatedAuthContentState();
}

class _AnimatedAuthContentState extends State<_AnimatedAuthContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Each section slides up and fades in at a different offset
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;

  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo: 0–50%
    _logoFade = _fade(0.0, 0.5);
    _logoSlide = _slide(0.0, 0.5);

    // Email/password form: 40–80%
    _formFade = _fade(0.4, 0.8);
    _formSlide = _slide(0.4, 0.8);

    _controller.forward();
  }

  Animation<double> _fade(double start, double end) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _slide(double start, double end) =>
      Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Logo ──────────────────────────────────────────────
        _FadeSlide(
          fade: _logoFade,
          slide: _logoSlide,
          child: const AlquimiaLogo(
            size: 140,
            showText: true,
            animate: true,
          ),
        ),
        const SizedBox(height: 40),

        // ── Error message ─────────────────────────────────────
        _FadeSlide(
          fade: _formFade,
          slide: _formSlide,
          child: const _ErrorBanner(),
        ),

        // ── Email / password form (Google button is inside) ───
        _FadeSlide(
          fade: _formFade,
          slide: _formSlide,
          child: const _EmailPasswordSignInSection(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Reusable fade + slide transition wrapper.
class _FadeSlide extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  const _FadeSlide({
    required this.fade,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(authNotifierProvider);
    if (errorMessage == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        errorMessage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Email / password section
// ─────────────────────────────────────────────────────────────────────────────

class _EmailPasswordSignInSection extends ConsumerStatefulWidget {
  const _EmailPasswordSignInSection();

  @override
  ConsumerState<_EmailPasswordSignInSection> createState() =>
      _EmailPasswordSignInSectionState();
}

class _EmailPasswordSignInSectionState
    extends ConsumerState<_EmailPasswordSignInSection> {
  bool _isLoading = false;

  Future<void> _handleEmailPasswordSignIn(
      String email, String password) async {
    setState(() => _isLoading = true);
    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmailPassword(email, password);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorMessage = ref.watch(authNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.emailPasswordSignIn,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        EmailPasswordForm(
          isLoading: _isLoading,
          errorMessage: errorMessage,
          onSignIn: _handleEmailPasswordSignIn,
          onGoogleSignIn: _handleGoogleSignIn,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.push('/password-recovery'),
          child: Text(l10n.forgotPassword),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.push('/register'),
          child: Text(l10n.createAccount),
        ),
      ],
    );
  }
}

