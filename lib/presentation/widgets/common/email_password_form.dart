import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Reusable email/password login form widget
class EmailPasswordForm extends StatefulWidget {
  final VoidCallback? onSubmit;
  final Function(String email, String password)? onSignIn;
  final VoidCallback? onGoogleSignIn;
  final bool isLoading;
  final String? errorMessage;

  const EmailPasswordForm({
    this.onSubmit,
    this.onSignIn,
    this.onGoogleSignIn,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validates password length
  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  void _handleSignIn() {
    if (_formKey.currentState!.validate()) {
      widget.onSignIn?.call(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: l10n.emailHint,
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              if (!_isValidEmail(value)) {
                return l10n.invalidEmail;
              }
              return null;
            },
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.password,
              hintText: l10n.passwordHint,
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                tooltip: l10n.togglePasswordVisibility,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.fieldRequired;
              }
              if (!_isValidPassword(value)) {
                return l10n.passwordTooShort;
              }
              return null;
            },
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 24),

          // Error message
          if (widget.errorMessage != null) ...[
            Text(
              widget.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Sign in button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : _handleSignIn,
              icon: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(l10n.signInButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Google sign-in icon button
          if (widget.onGoogleSignIn != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Tooltip(
                message: l10n.signInWithGoogle,
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onGoogleSignIn,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: _GoogleLogo(size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Google "G" logo painted with official brand colours
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleLogo extends StatelessWidget {
  final double size;
  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    final double ringOuter = r;
    final double ringInner = r * 0.58;
    final Rect outerRect =
        Rect.fromCircle(center: Offset(cx, cy), radius: ringOuter);

    // Red  – top-right  (-45° → 45°)
    paint.color = const Color(0xFFEA4335);
    _drawArcSegment(canvas, outerRect, cx, cy, -45, 90, paint);

    // Yellow – bottom-right (45° → 135°)
    paint.color = const Color(0xFFFBBC05);
    _drawArcSegment(canvas, outerRect, cx, cy, 45, 90, paint);

    // Green – bottom-left (135° → 225°)
    paint.color = const Color(0xFF34A853);
    _drawArcSegment(canvas, outerRect, cx, cy, 135, 90, paint);

    // Blue – left + top-left (225° → 315°)
    paint.color = const Color(0xFF4285F4);
    _drawArcSegment(canvas, outerRect, cx, cy, 225, 90, paint);

    // White inner circle → creates the ring
    canvas.drawCircle(Offset(cx, cy), ringInner, Paint()..color = Colors.white);

    // Blue right arc + horizontal bar (the crossbar of the G)
    paint.color = const Color(0xFF4285F4);
    _drawArcSegment(canvas, outerRect, cx, cy, -15, 60, paint);
    final double barTop = cy - r * 0.13;
    final double barBottom = cy + r * 0.13;
    canvas.drawRect(Rect.fromLTRB(cx, barTop, cx + r, barBottom), paint);

    // Restore inner white circle
    canvas.drawCircle(Offset(cx, cy), ringInner, Paint()..color = Colors.white);
  }

  void _drawArcSegment(
    Canvas canvas,
    Rect outerRect,
    double cx,
    double cy,
    double startDeg,
    double sweepDeg,
    Paint paint,
  ) {
    const double toRad = 3.141592653589793 / 180.0;
    final Path path = Path()
      ..moveTo(cx, cy)
      ..arcTo(outerRect, startDeg * toRad, sweepDeg * toRad, false)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
