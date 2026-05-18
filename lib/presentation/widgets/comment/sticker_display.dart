import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget de solo lectura que muestra los stickers adjuntos a un comentario.
///
/// Solo soporta URLs (stickers subidos por usuarios). Los IDs legacy del
/// sistema anterior se ignoran silenciosamente.
/// Si no hay stickers válidos, no renderiza nada.
class StickerDisplay extends StatelessWidget {
  /// URLs de stickers a mostrar. Solo se renderizan strings que comiencen con "http".
  final List<String> stickers;

  const StickerDisplay({required this.stickers, super.key});

  @override
  Widget build(BuildContext context) {
    // Filtrar solo URLs válidas (ignorar IDs legacy)
    final urls = stickers.where((s) => s.startsWith('http')).toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: urls.map((url) => _buildSticker(url)).toList(),
    );
  }

  Widget _buildSticker(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      placeholder: (context, url) => const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => const Icon(
        Icons.broken_image,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}
