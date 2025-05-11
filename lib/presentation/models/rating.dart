class Rating {
  final String? id;
  final String userId;
  final int stars;
  final String comment;
  final String ratedAt;

  Rating({
    this.id,
    required this.userId,
    required this.stars,
    required this.comment,
    required this.ratedAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'],
      userId: json['userId'] ?? '',
      stars: json['stars'] ?? 0,
      comment: json['comment'] ?? '',
      ratedAt: json['ratedAt'] ?? '',
    );
  }
}