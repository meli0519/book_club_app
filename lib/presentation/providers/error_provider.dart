import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a pending error message to be shown as a SnackBar.
/// null = no error pending.
///
/// Usage:
///   // In a service/notifier, set an error:
///   ref.read(networkErrorProvider.notifier).state = 'Network error message';
///
///   // In a widget (e.g. root scaffold), listen and show SnackBar:
///   ref.listen(networkErrorProvider, (_, message) {
///     if (message != null) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(message)),
///       );
///       ref.read(networkErrorProvider.notifier).state = null;
///     }
///   });
///
/// Requirement 12.6 – descriptive error message without blocking navigation.
final networkErrorProvider = StateProvider<String?>((ref) => null);

/// Helper extension to show a network error SnackBar from any widget.
extension NetworkErrorX on WidgetRef {
  /// Shows a SnackBar with [message] and clears the error state.
  /// Does NOT block navigation.
  void showNetworkError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '✕',
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}

/// A widget that listens to [networkErrorProvider] and automatically shows
/// a SnackBar whenever a network error is set.
///
/// Wrap the root [Scaffold] (or [MaterialApp]) with this widget to get
/// global error handling without blocking navigation.
///
/// Requirement 12.6
class NetworkErrorListener extends ConsumerWidget {
  final Widget child;

  const NetworkErrorListener({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(networkErrorProvider, (_, message) {
      if (message == null) return;
      // Clear the error immediately so it doesn't re-show on rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(networkErrorProvider.notifier).state = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '✕',
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    });

    return child;
  }
}
