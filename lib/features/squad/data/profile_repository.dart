import 'dart:typed_data';

import '../../auth/data/models/app_user.dart';

/// عقد بيانات البروفايل.
abstract interface class ProfileRepository {
  /// بروفايلي أنا كامل (null لو مش مسجّل).
  Future<AppUser?> fetchMine();

  /// نقاط يوزر (للهوم).
  Future<int> points(String userId);

  /// أعلى نقط جابها في ماتش واحد.
  Future<int> bestMatch(String userId);

  /// نقطي في جولة واحدة (المباشر — بتبدأ من صفر كل جولة).
  Future<int> roundPoints(String userId, DateTime roundEnd);

  /// حفظ توكن الإشعارات (FCM) للمستخدم.
  Future<void> saveFcmToken(String userId, String token);

  /// رفع صورة البروفايل وحفظها — بيرجّع الرابط.
  Future<String> uploadAvatar(String userId, Uint8List bytes, String extension);
}
