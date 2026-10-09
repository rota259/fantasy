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

  /// (مدير منطقة) يرشّح هدف/تصدّي من ماتش ليه خلص — بيتجمع في تصويت الجولة لمنطقته. kind = goal | save.
  Future<void> nominate(String kind, String matchId, String playerId, String videoUrl);

  /// (مدير منطقة) يشيل ترشيحه.
  Future<void> removeNomination(String optionId);

  /// (مدير منطقة) ترشيحاتي في آخر ٣٠ يوم.
  Future<List<AwardNomination>> myNominations();

  /// (مدير) هدف/تصدّي الموسم من فايزين الجولات. kind = goal | save.
  Future<String> createSeasonAward(String kind);
}
