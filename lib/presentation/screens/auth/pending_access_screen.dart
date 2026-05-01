import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// Shown when the user has no membership document (request was just created)
/// or when the membership was rejected.
class PendingAccessScreen extends ConsumerWidget {
  const PendingAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membershipAsync = ref.watch(membershipStatusProvider);

    final isRejected = membershipAsync.valueOrNull?.status ==
        MembershipStatus.rejected;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isRejected ? Icons.block : Icons.hourglass_empty,
                  size: 72,
                  color: isRejected
                      ? Theme.of(context).colorScheme.error
                      : Colors.deepPurple,
                ),
                const SizedBox(height: 24),
                Text(
                  isRejected ? l10n.rejectedTitle : l10n.pendingAccessTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  isRejected ? l10n.rejectedMessage : l10n.pendingAccessMessage,
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
