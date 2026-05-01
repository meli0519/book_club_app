import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/membership_provider.dart';
import '../../providers/user_management_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../../domain/models/membership.dart';
import '../../../domain/models/app_user.dart';

/// Unified screen for leaders to manage both pending membership requests
/// and all users in the system.
/// Requirement 2.2, 10.2, 10.3
class MemberManagementScreen extends ConsumerWidget {
  const MemberManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.memberManagementTitle),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.pending_actions),
                text: l10n.pendingRequests,
              ),
              Tab(
                icon: const Icon(Icons.people),
                text: l10n.allUsers,
              ),
            ],
          ),
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
        body: const TabBarView(
          children: [
            _PendingRequestsTab(),
            _AllUsersTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Pending Requests
// ---------------------------------------------------------------------------

class _PendingRequestsTab extends ConsumerWidget {
  const _PendingRequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pendingAsync = ref.watch(pendingMembershipsProvider);

    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            e.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      data: (members) => members.isEmpty
          ? Center(child: Text(l10n.noPendingRequests))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _PendingMembershipCard(membership: members[index]),
            ),
    );
  }
}

class _PendingMembershipCard extends ConsumerWidget {
  final Membership membership;

  const _PendingMembershipCard({required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final processingUserId = ref.watch(membershipActionsProvider);
    final isProcessing = processingUserId == membership.userId;
    final dateStr = DateFormat.yMMMd().format(membership.requestedAt);
    final userAsync = ref.watch(memberUserProvider(membership.userId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row: avatar + name + email
            userAsync.when(
              loading: () => const _UserInfoSkeleton(),
              error: (_, __) => _UserInfoFallback(userId: membership.userId),
              data: (user) => user != null
                  ? _UserInfoRow(user: user)
                  : _UserInfoFallback(userId: membership.userId),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.requestedAt(dateStr),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  OutlinedButton(
                    onPressed: () => _reject(context, ref, l10n),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Text(l10n.reject),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _approve(context, ref, l10n),
                    child: Text(l10n.approve),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;
    try {
      await ref
          .read(membershipActionsProvider.notifier)
          .approve(membership.userId, authUser.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.memberApprovedSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.memberActionError)),
        );
      }
    }
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    try {
      await ref
          .read(membershipActionsProvider.notifier)
          .reject(membership.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.memberRejectedSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.memberActionError)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Tab 2: All Users
// ---------------------------------------------------------------------------

class _AllUsersTab extends ConsumerWidget {
  const _AllUsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(usersWithMembershipsProvider);

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.errorLoadingUsers,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      data: (users) => users.isEmpty
          ? Center(child: Text(l10n.noUsersFound))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _UserManagementCard(userWithMembership: users[index]),
            ),
    );
  }
}

class _UserManagementCard extends ConsumerWidget {
  final UserWithMembership userWithMembership;

  const _UserManagementCard({required this.userWithMembership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = userWithMembership.user;
    final processingUserId = ref.watch(userManagementActionsProvider);
    final isProcessing = processingUserId == user.uid;
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final isCurrentUser = currentUser?.uid == user.uid;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: user.photoUrl.isNotEmpty
                      ? NetworkImage(user.photoUrl)
                      : null,
                  child: user.photoUrl.isEmpty
                      ? Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName
                                  : l10n.noName,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentUser) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                l10n.you,
                                style: const TextStyle(fontSize: 11),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 0),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status and role chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: user.isLeader ? l10n.leader : l10n.member,
                  icon: user.isLeader ? Icons.star : Icons.person,
                  color: user.isLeader
                      ? Colors.amber
                      : Theme.of(context).colorScheme.primary,
                ),
                _StatusChip(
                  label: _getMembershipStatusLabel(l10n),
                  icon: _getMembershipStatusIcon(),
                  color: _getMembershipStatusColor(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            if (isProcessing)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Toggle role button (disabled for current user)
                  OutlinedButton.icon(
                    onPressed: isCurrentUser
                        ? null
                        : () => _toggleRole(context, ref, l10n),
                    icon: Icon(
                      user.isLeader ? Icons.person : Icons.star,
                      size: 18,
                    ),
                    label: Text(
                      user.isLeader ? l10n.makeAMember : l10n.makeALeader,
                    ),
                  ),
                  // Activate/Deactivate button (disabled for current user)
                  if (userWithMembership.isActive)
                    FilledButton.icon(
                      onPressed: isCurrentUser
                          ? null
                          : () => _deactivate(context, ref, l10n),
                      icon: const Icon(Icons.block, size: 18),
                      label: Text(l10n.deactivate),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else if (userWithMembership.isRejected)
                    FilledButton.icon(
                      onPressed: () => _reactivate(context, ref, l10n),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: Text(l10n.reactivate),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getMembershipStatusLabel(AppLocalizations l10n) {
    if (userWithMembership.isActive) return l10n.active;
    if (userWithMembership.isPending) return l10n.pending;
    if (userWithMembership.isRejected) return l10n.inactive;
    return l10n.unknown;
  }

  IconData _getMembershipStatusIcon() {
    if (userWithMembership.isActive) return Icons.check_circle;
    if (userWithMembership.isPending) return Icons.hourglass_empty;
    if (userWithMembership.isRejected) return Icons.block;
    return Icons.help;
  }

  Color _getMembershipStatusColor(BuildContext context) {
    if (userWithMembership.isActive) return Colors.green;
    if (userWithMembership.isPending) return Colors.orange;
    if (userWithMembership.isRejected) {
      return Theme.of(context).colorScheme.error;
    }
    return Colors.grey;
  }

  Future<void> _toggleRole(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    try {
      await ref
          .read(userManagementActionsProvider.notifier)
          .toggleRole(userWithMembership.user.uid, userWithMembership.user.role);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.roleUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.roleUpdateError)),
        );
      }
    }
  }

  Future<void> _deactivate(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeactivation),
        content: Text(l10n.deactivationWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deactivate),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(userManagementActionsProvider.notifier)
          .deactivate(userWithMembership.user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userDeactivatedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userActionError)),
        );
      }
    }
  }

  Future<void> _reactivate(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) return;

    try {
      await ref
          .read(userManagementActionsProvider.notifier)
          .reactivate(userWithMembership.user.uid, currentUser.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userReactivatedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.userActionError)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _UserInfoRow extends StatelessWidget {
  final AppUser user;

  const _UserInfoRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: user.photoUrl.isNotEmpty
              ? NetworkImage(user.photoUrl)
              : null,
          child: user.photoUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 18),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName.isNotEmpty ? user.displayName : '—',
                style: Theme.of(context).textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserInfoFallback extends StatelessWidget {
  final String userId;

  const _UserInfoFallback({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 24, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            userId,
            style: Theme.of(context).textTheme.titleSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _UserInfoSkeleton extends StatelessWidget {
  const _UserInfoSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(radius: 24),
        SizedBox(width: 12),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}
