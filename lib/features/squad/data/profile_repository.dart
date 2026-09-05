import '../../auth/data/models/app_user.dart';

/// عقد بيانات البروفايل.
abstract interface class ProfileRepository {
  /// حفظ ids لاعيبة التشكيلة والكابتن في profiles.
  Future<void> updateTeam(String userId, List<String> playerIds, String? captainId);

  /// جلب بروفايل أي مستخدم (لخصم التحدّي مثلًا).
  Future<AppUser?> fetchProfile(String userId);
}
