import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/app_user.dart';
import '../../providers/auth_provider.dart';

/// A widget that conditionally renders [child] based on the current user's role.
///
/// When [requiredRole] is [UserRole.leader], the child is only shown to leaders.
/// Members see nothing (or [fallback] if provided).
///
/// Requirement 3.3: hide create/edit/delete controls for members.
class RoleGuard extends ConsumerWidget {
  /// The minimum role required to see [child].
  final UserRole requiredRole;

  /// The widget to show when the user has the required role.
  final Widget child;

  /// Optional widget to show when the user does NOT have the required role.
  /// Defaults to [SizedBox.shrink] (invisible).
  final Widget? fallback;

  const RoleGuard({
    required this.requiredRole,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);

    final hasAccess = switch (requiredRole) {
      UserRole.leader => role == UserRole.leader,
      UserRole.member => true, // both roles satisfy member requirement
    };

    if (hasAccess) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
