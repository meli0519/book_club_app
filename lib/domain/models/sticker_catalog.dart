/// Catálogo centralizado de stickers disponibles en la app.
///
/// Actúa como única fuente de verdad para el mapa ID → ruta de asset,
/// utilizado por StickerPicker, StickerDisplay y la validación en CommentService.
abstract class StickerCatalog {
  /// Mapa de ID de sticker → ruta de asset local.
  ///
  /// Los IDs son strings snake_case; las rutas apuntan a assets/stickers/.
  static const Map<String, String> all = {
    'sticker_heart':  'assets/stickers/sticker_heart.png',
    'sticker_laugh':  'assets/stickers/sticker_laugh.png',
    'sticker_cry':    'assets/stickers/sticker_cry.png',
    'sticker_wow':    'assets/stickers/sticker_wow.png',
    'sticker_fire':   'assets/stickers/sticker_fire.png',
    'sticker_clap':   'assets/stickers/sticker_clap.png',
    'sticker_think':  'assets/stickers/sticker_think.png',
    'sticker_book':   'assets/stickers/sticker_book.png',
    'sticker_star':   'assets/stickers/sticker_star.png',
    'sticker_party':  'assets/stickers/sticker_party.png',
    'sticker_love':   'assets/stickers/sticker_love.png',
    'sticker_cool':   'assets/stickers/sticker_cool.png',
    'sticker_sad':    'assets/stickers/sticker_sad.png',
    'sticker_angry':  'assets/stickers/sticker_angry.png',
    'sticker_sleep':  'assets/stickers/sticker_sleep.png',
    'sticker_idea':   'assets/stickers/sticker_idea.png',
    'sticker_magic':  'assets/stickers/sticker_magic.png',
    'sticker_coffee': 'assets/stickers/sticker_coffee.png',
    'sticker_moon':   'assets/stickers/sticker_moon.png',
    'sticker_pen':    'assets/stickers/sticker_pen.png',
  };

  /// Lista de IDs en el mismo orden que las claves de [all].
  ///
  /// Usar esta lista en StickerPicker para iterar sin necesidad de llamar
  /// a [all.keys], garantizando un orden estable y predecible.
  static const List<String> ids = [
    'sticker_heart',
    'sticker_laugh',
    'sticker_cry',
    'sticker_wow',
    'sticker_fire',
    'sticker_clap',
    'sticker_think',
    'sticker_book',
    'sticker_star',
    'sticker_party',
    'sticker_love',
    'sticker_cool',
    'sticker_sad',
    'sticker_angry',
    'sticker_sleep',
    'sticker_idea',
    'sticker_magic',
    'sticker_coffee',
    'sticker_moon',
    'sticker_pen',
  ];

  // Previene la instanciación de esta clase utilitaria.
  StickerCatalog._();
}
