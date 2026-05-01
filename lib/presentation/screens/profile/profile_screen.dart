import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/language_selector.dart';
import '../../widgets/common/theme_selector.dart';

/// Displays the current user's profile information.
/// Subtasks 18.1–18.5: name, photo, email, registration date,
/// edit profile button and sign-out button.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.bookDetailError)),
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.bookNotFound));
          }

          final initials = user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : '?';

          final formattedDate =
              DateFormat.yMMMd().format(user.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // 18.2 – Profile photo with initials fallback
                CircleAvatar(
                  radius: 56,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 24),
                // 18.1 – Display name
                Text(
                  user.displayName.isNotEmpty
                      ? user.displayName
                      : user.email,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 18.4 – Additional info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: l10n.email,
                          value: user.email,
                        ),
                        const Divider(),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.registrationDate(formattedDate),
                          value: '',
                          showValue: false,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Settings section
                Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.settings,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const LanguageSelector(),
                      const Divider(height: 1),
                      const ThemeSelector(),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // 18.3 – Edit Profile button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.editProfile),
                    onPressed: () => context.push(AppRoutes.editProfile),
                  ),
                ),
                const SizedBox(height: 12),
                // 18.5 – Sign out button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOut),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    onPressed: () =>
                        _confirmSignOut(context, ref, l10n),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutConfirmTitle),
        content: Text(l10n.signOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}

// ---------------------------------------------------------------------------
// Helper widget
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showValue = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: showValue
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(value,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  )
                : Text(label,
                    style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
