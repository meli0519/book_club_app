class Rating {
  final String authorId;
  final int value; // 1-5
  final String? comment;

  const Rating({
    required this.authorId,
    required this.value,
    this.comment,
  });

  factory Rating.fromMap(Map<String, dynamic> map, String id) {
    return Rating(
      authorId: map['authorId'] as String,
      value: map['value'] as int,
      comment: map['comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'value': value,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
    };
  }
}
