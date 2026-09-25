import 'package:equatable/equatable.dart';

/// تقييم ملعب: نجوم + تعليق + مين كتبه.
class VenueReview extends Equatable {
  const VenueReview({
    required this.userId,
    required this.name,
    required this.stars,
    this.comment,
    this.photoUrl,
    this.createdAt,
  });

  final String userId;
  final String name;
  final int stars; // ١..٥
  final String? comment;
  final String? photoUrl;
  final DateTime? createdAt;

  factory VenueReview.fromMap(Map<String, dynamic> m) => VenueReview(
    userId: m['user_id'].toString(),
    name: (m['name'] ?? '') as String,
    stars: (m['stars'] as num).toInt(),
    comment: m['comment'] as String?,
    photoUrl: m['photo_url'] as String?,
    createdAt: m['created_at'] == null ? null : DateTime.tryParse(m['created_at'].toString())?.toLocal(),
  );

  @override
  List<Object?> get props => [userId, stars, comment, createdAt];
}
