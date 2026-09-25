import 'models/poll.dart';

/// عقد التصويتات (هدف/تصدّي الجولة والموسم + تعادل تشكيلة الجولة).
abstract interface class PollsRepository {
  /// أحدث تصويت من النوع ده + اختياراته ونتايجه وصوت اليوزر.
  Future<PollView?> latestPoll(String kind, String userId);

  /// تصويت التعادل بتاع جولة معيّنة (لو اتعمل).
  Future<PollView?> tieFor(DateTime windowEnd, String userId);

  /// (مدير) قفل التصويت.
  Future<void> closePoll(String pollId);

  /// (يوزر) يصوّت لاختيار (بيستبدل صوته القديم في نفس التصويت).
  Future<void> vote(String pollId, String optionId, String userId);

  /// (مدير) تصويت هدف/تصدّي الجولة بمرشّحين + لينكات فيديو.
  Future<String> createAward(String kind, String question, List<NewPollOption> options, DateTime? closesAt);

  /// (مدير) هدف/تصدّي الموسم من فايزين الجولات. kind = goal | save.
  Future<String> createSeasonAward(String kind);
}
