import '../players/data/models/player.dart';

/// توصية المدرّب.
class CoachAdvice {
  const CoachAdvice({
    required this.out,
    required this.incoming,
    required this.expectedGain,
    required this.confidence,
    required this.captain,
  });

  final Player out; // يخرج
  final Player incoming; // يدخل
  final int expectedGain; // نقاط متوقّعة
  final int confidence; // نسبة الثقة %
  final Player captain; // كابتن مقترح
}

/// محرك قواعد بسيط لاقتراح تحويل وكابتن (heuristic — مش AI).
abstract final class CoachEngine {
  CoachEngine._();

  static CoachAdvice? recommend(
    List<Player> squad,
    List<Player> market,
    double remaining,
  ) {
    if (squad.isEmpty) return null;

    // الكابتن المقترح = أعلى فورمة في التشكيلة.
    final captain = squad.reduce((a, b) => a.form >= b.form ? a : b);
    // المرشّح للخروج = أقل فورمة.
    final out = squad.reduce((a, b) => a.form <= b.form ? a : b);

    // البدائل: من السوق، مش مملوكين، نفس المركز، وفي حدود الميزانية.
    final owned = squad.map((p) => p.id).toSet();
    final budgetFor = remaining + out.price;
    final candidates = market
        .where((m) =>
            !owned.contains(m.id) &&
            m.position == out.position &&
            m.price <= budgetFor)
        .toList();
    if (candidates.isEmpty) return null;

    final incoming = candidates.reduce((a, b) => a.form >= b.form ? a : b);
    if (incoming.form <= out.form) return null; // مفيش تحسين فعلي

    final diff = incoming.form - out.form;
    final gain = (diff * 0.8).round();
    final confidence = (55 + diff * 6).clamp(40, 95).round();

    return CoachAdvice(
      out: out,
      incoming: incoming,
      expectedGain: gain,
      confidence: confidence,
      captain: captain,
    );
  }
}
