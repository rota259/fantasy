import 'models/poll.dart';

/// عقد التصويتات (نجم الجولة / تحدّي الجولة).
abstract interface class PollsRepository {
  /// أحدث تصويت من النوع ده (مفتوح أو مقفول) + اختياراته ونتايجه وصوت اليوزر.
  Future<PollView?> latestPoll(String kind, String userId);

  /// (مدير) قفل التصويت.
  Future<void> closePoll(String pollId);

  /// (يوزر) يصوّت لاختيار (بيستبدل صوته القديم في نفس التصويت).
  Future<void> vote(String pollId, String optionId, String userId);

  /// (مدير) يعمل نجم الجولة من لاعيبة مرشّحين. بيرجّع id التصويت.
  Future<String> createStar(List<({String id, String name})> players);

  /// (مدير) يعمل تحدّي بسؤال واختيارات نصّية.
  Future<String> createChallenge(String question, List<String> options);
}
