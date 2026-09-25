import 'models/venue_review.dart';

/// عقد تقييمات الملاعب (أي يوزر ما عدا صاحب الملعب).
abstract interface class ReviewsRepository {
  /// تقييمات ملعب (الأحدث الأول).
  Future<List<VenueReview>> list(String venueId);

  /// تقييمي (بيستبدل القديم).
  Future<void> save(String venueId, String userId, int stars, String? comment);

  Future<void> delete(String venueId, String userId);
}
