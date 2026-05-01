import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class PasswordRecoveryScreen extends ConsumerWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.passwordRecoveryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_reset, size: 80, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  Text(
                    l10n.passwordRecoveryTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.passwordRecoveryDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _PasswordRecoveryForm(l10n: l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordRecoveryForm extends ConsumerStatefulWidget {
  final AppLocalizations l10n;

  const _PasswordRecoveryForm({required this.l10n});

  @override
  ConsumerState<_PasswordRecoveryForm> createState() =>
      _PasswordRecoveryFormState();
}

class _PasswordRecoveryFormState extends ConsumerState<_PasswordRecoveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.passwordResetSent),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = widget.l10n.passwordResetError;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: widget.l10n.email,
              hintText: widget.l10n.emailHint,
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return widget.l10n.fieldRequired;
              }
              if (!_isValidEmail(value)) {
                return widget.l10n.invalidEmail;
              }
              return null;
            },
            enabled: !_isLoading,
          ),
          const SizedBox(height: 24),

          // Error message
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],

          // Send reset link button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handlePasswordReset,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mail),
              label: Text(widget.l10n.sendResetLink),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Back to sign in button
          TextButton(
            onPressed: _isLoading ? null : () => context.pop(),
            child: Text(widget.l10n.backToSignIn),
          ),
        ],
      ),
    );
  }
}
