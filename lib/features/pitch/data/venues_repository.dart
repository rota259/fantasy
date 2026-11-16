import 'dart:typed_data';

import 'models/venue.dart';
import 'models/venue_extras.dart';

/// عقد بيانات الملاعب.
abstract interface class VenuesRepository {
  /// كل الملاعب.
  Future<List<Venue>> fetchAll();

  /// ملعب واحد (null = اتمسح).
  Future<Venue?> fetchById(String id);

  /// الملاعب اللي اليوزر ده صاحبها.
  Future<List<Venue>> fetchOwned(String userId);

  /// إضافة ملعب (id فاضي) أو تعديله — صاحبه أو المدير.
  Future<void> save(Venue venue);

  /// حذف ملعب — صاحبه أو المدير.
  Future<void> deleteVenue(String id);

  /// رفع صورة في فولدر اليوزر وبيرجّع رابطها.
  Future<String> uploadPhoto(String userId, Uint8List bytes, String extension);

  /// متوسط تقييم كل ملعب: venueId → (المتوسط، العدد). بعد التجديد: التقييمات الجديدة بس.
  Future<Map<String, ({double avg, int count})>> ratings();

  /// (أدمن أو مشرف المنطقة) توثيق ملعب · شيل التوثيق · رفض طلب التوثيق ([on] = false).
  Future<void> verify(String id, bool on);

  /// (صاحب الملعب) اطلب التوثيق — الأدمن ومشرف المنطقة يوصلهم إشعار.
  Future<void> requestVerification(String id);

  /// (أدمن أو مشرف) الملاعب اللي طالبة توثيق.
  Future<List<PendingVenue>> pending();

  /// (صاحب ملعب موثّق) إعلان لأهل المنطقة: [kind] = update أو renovation (بيبدأ التقييم من الأول).
  Future<void> postUpdate(String id, String kind, String body);

  /// آخر أخبار الملعب (الأحدث الأول).
  Future<List<VenueUpdate>> updates(String id);

  /// إحصائيات الملعب وأسطورته.
  Future<VenueStats> stats(String id);

  /// (صاحب الملعب) ماتشات خلصت في ملعبه ومستنية يأكّد إنها اتلعبت.
  Future<List<VenueMatch>> pendingMatches(String venueId);

  /// (صاحب الملعب) الماتش اتلعب ([ok]) ولا لأ ([note] = إيه اللي حصل).
  Future<void> confirmMatch(String matchId, bool ok, String? note);

  /// أنا صاحب ملعب موثّق (أقدر أعمل بطولات).
  Future<bool> amHost();
}
