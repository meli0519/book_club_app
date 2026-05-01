import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../domain/models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import 'theme_selector_dialog.dart';

/// Common navigation drawer used across the app.
/// Shows user info and navigation options based on role and membership status.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserAsync = ref.watch(currentUserProvider);
    final isLeader = currentUserAsync.valueOrNull?.isLeader ?? false;

    final appBarColor = Theme.of(context).appBarTheme.backgroundColor
        ?? colorScheme.primary;

    return Drawer(
      child: Container(
        color: appBarColor,
        child: Column(
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: appBarColor),
              child: currentUserAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (user) => _DrawerHeader(user: user, l10n: l10n),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: Text(
                      l10n.homeScreenTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.home);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.white),
                    title: Text(
                      l10n.drawerProfile,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.profile);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book, color: Colors.white),
                    title: Text(
                      l10n.drawerBooks,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.books);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.my_library_books, color: Colors.white),
                    title: Text(
                      l10n.personalBooksTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.personalBooks);
                    },
                  ),
                  if (isLeader)
                    ListTile(
                      leading: const Icon(Icons.people, color: Colors.white),
                      title: Text(
                        l10n.drawerMembers,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.memberManagement);
                      },
                    ),
                  if (isLeader)
                    ListTile(
                      leading: const Icon(Icons.quiz, color: Colors.white),
                      title: Text(
                        l10n.reviewQuestionsManagementTitle,
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.reviewQuestionsManagement);
                      },
                    ),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(Icons.palette, color: Colors.white),
                    title: Text(
                      l10n.themeDialogTitle,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      ThemeSelectorDialog.show(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final AppUser? user;
  final AppLocalizations l10n;

  const _DrawerHeader({required this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: user!.photoUrl.isNotEmpty
              ? NetworkImage(user!.photoUrl)
              : null,
          backgroundColor: Colors.white24,
          child: user!.photoUrl.isEmpty
              ? Text(
                  user!.displayName.isNotEmpty
                      ? user!.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.drawerWelcome,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          user!.displayName.isNotEmpty ? user!.displayName : user!.email,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
