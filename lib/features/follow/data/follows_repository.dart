/// عقد متابعة الماتشات لايف (كل أحداث الماتش بتوصلك إشعار). آخرك ٣ ماتشات في اليوم.
abstract interface class FollowsRepository {
  /// ids الماتشات اللي بتتابعها.
  Future<Set<String>> mine(String userId);

  /// متابعة — بيرمي رسالة السيرفر لو عدّيت الحد.
  Future<void> follow(String matchId, String userId);

  Future<void> unfollow(String matchId, String userId);
}
