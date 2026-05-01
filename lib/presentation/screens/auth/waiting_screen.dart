import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// Shown while the user's membership request is pending leader approval.
class WaitingScreen extends ConsumerWidget {
  const WaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.schedule,
                  size: 72,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.waitingTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.waitingMessage,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
