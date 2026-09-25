import 'models/user_badge.dart';

/// عقد الشارات (السيرفر بيحسبها ويدّيها — هنا قراية بس).
abstract interface class BadgesRepository {
  /// كل شارات يوزر (حتى اللي لسه بتقدّم فيها).
  Future<List<UserBadge>> forUser(String userId);

  /// أحسن شارات لمجموعة يوزرز (للترتيب): userId → الشارات اللي خدها بس (الأعلى أولًا).
  Future<Map<String, List<UserBadge>>> earnedFor(List<String> userIds);
}
