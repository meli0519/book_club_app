class Rating {
  final String authorId;
  final double value; // 0.5–5.0 in 0.5 increments
  final String? comment;
  final List<String> stickers; // URLs de stickers adjuntos al comentario

  const Rating({
    required this.authorId,
    required this.value,
    this.comment,
    this.stickers = const [],
  });

  factory Rating.fromMap(Map<String, dynamic> map, String id) {
    return Rating(
      authorId: map['authorId'] as String,
      value: (map['value'] as num).toDouble(),
      comment: map['comment'] as String?,
      stickers: map['stickers'] != null
          ? List<String>.from(map['stickers'] as List)
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'value': value,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (stickers.isNotEmpty) 'stickers': stickers,
    };
  }
}
