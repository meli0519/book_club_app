import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import 'package:book_club_app/presentation/providers/sticker_provider.dart';

/// Pure toggle function — exported for testability.
///
/// - If [id] is in [current] → returns list with [id] removed.
/// - Else if [current.length] < [max] → returns list with [id] added.
/// - Else → returns [current] unchanged (limit reached).
List<String> toggleSticker(List<String> current, String id, int max) {
  if (current.contains(id)) {
    return List<String>.from(current)..remove(id);
  } else if (current.length < max) {
    return List<String>.from(current)..add(id);
  }
  return current;
}

/// Widget que muestra una cuadrícula de stickers del usuario para seleccionar.
///
/// Permite seleccionar hasta [maxStickers] stickers de los subidos por el usuario.
/// Llama a [onConfirm] con la lista de URLs seleccionadas al confirmar.
class StickerPicker extends ConsumerStatefulWidget {
  /// URLs de stickers pre-seleccionados al abrir el picker.
  final List<String> selectedStickers;

  /// Número máximo de stickers seleccionables simultáneamente.
  final int maxStickers;

  /// Callback invocado con la lista de URLs seleccionadas al confirmar.
  final void Function(List<String> stickers) onConfirm;

  /// ID del usuario actual (para cargar sus stickers).
  final String userId;

  const StickerPicker({
    required this.selectedStickers,
    required this.onConfirm,
    required this.userId,
    this.maxStickers = 5,
    super.key,
  });

  @override
  ConsumerState<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends ConsumerState<StickerPicker> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedStickers);
  }

  void _toggleSticker(String url) {
    setState(() {
      _selected = toggleSticker(_selected, url, widget.maxStickers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stickersAsync = ref.watch(userStickersStreamProvider(widget.userId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            l10n.stickerPickerTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Flexible(
          child: stickersAsync.when(
            data: (stickers) {
              if (stickers.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_emotions_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noStickersMessage,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: stickers.length,
                itemBuilder: (context, index) {
                  final sticker = stickers[index];
                  final isSelected = _selected.contains(sticker.imageUrl);
                  final isDisabled =
                      !isSelected && _selected.length >= widget.maxStickers;

                  return GestureDetector(
                    onTap: () => _toggleSticker(sticker.imageUrl),
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: isDisabled ? 0.35 : 1.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              sticker.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.broken_image);
                              },
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Error: $error'),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_selected);
                  Navigator.of(context).pop();
                },
                child: Text(l10n.stickerPickerConfirm),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
