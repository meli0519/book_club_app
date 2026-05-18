import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import 'package:book_club_app/presentation/widgets/sticker/sticker_gallery.dart';
import 'package:book_club_app/presentation/providers/auth_provider.dart';
import 'package:book_club_app/presentation/widgets/common/app_drawer.dart';

/// Pantalla de gestión de stickers del usuario.
/// 
/// Permite al usuario ver, subir y eliminar sus stickers personalizados.
class StickerManagementScreen extends ConsumerWidget {
  const StickerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stickerGalleryTitle),
      ),
      drawer: const AppDrawer(),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(l10n.pleaseSignIn),
            );
          }

          return StickerGallery(userId: user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
