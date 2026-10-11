import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// أنواع تحدّي الجولة — المدير بيختار واحد أو أكتر.
abstract final class ChallengeMode {
  static const diff = 'diff'; // فرق الأهداف (+٥ والسلسلة ٥ ← ٧ ← ١٠)
  static const duel = 'duel'; // مين فيهم؟ (+٣)
  static const quiz = 'quiz'; // ٣ أسئلة (كل واحد +٢ · التلاتة +١٠)
  static const lowest = 'lowest'; // المعكوس: أقل الأساسيين نقط (+٤)

  static const all = [diff, duel, quiz, lowest];

  static String label(String m) => switch (m) {
    diff => 'فرق الأهداف',
    duel => 'مين فيهم؟',
    quiz => '٣ أسئلة سريعة',
    lowest => 'التحدّي المعكوس',
    _ => m,
  };

  static IconData icon(String m) => switch (m) {
    diff => Icons.scoreboard_outlined,
    duel => Icons.compare_arrows,
    quiz => Icons.quiz_outlined,
    lowest => Icons.trending_down,
    _ => Icons.flag_outlined,
  };

  static String hint(String m) => switch (m) {
    diff => 'توقّع النتيجة — فرق الأهداف صح +٥، ولو صح ورا بعض: +٧ وبعدين +١٠',
    duel => 'لاعب من كل فريق — مين يجيب نقط أكتر في الماتش؟ +٣',
    quiz => 'مين يكسب · الأهداف أكتر من ٦ · مين يسجّل الأول — كل واحد +٢ والتلاتة +١٠',
    lowest => 'مين أقل لاعب نقط من الأساسيين؟ +٤',
    _ => '',
  };
}

typedef ChallengePlayer = ({String id, String name, String team, bool gk});

/// إجاباتي في الأنواع الجديدة (فرق الأهداف لوحده في Prediction).
class ChallengeAnswers extends Equatable {
  const ChallengeAnswers({this.duel, this.winner, this.over, this.first, this.lowest});

  final String? duel; // id اللاعب
  final String? winner; // a | b | draw
  final bool? over; // أكتر من ٦ أهداف
  final String? first; // أول هدّاف
  final String? lowest; // أقل الأساسيين

  factory ChallengeAnswers.fromMap(Map<String, dynamic>? m) => m == null
      ? const ChallengeAnswers()
      : ChallengeAnswers(
          duel: m['duel_pick'] as String?,
          winner: m['q_winner'] as String?,
          over: m['q_over'] as bool?,
          first: m['q_first'] as String?,
          lowest: m['lowest_pick'] as String?,
        );

  ChallengeAnswers copyWith({String? duel, String? winner, bool? over, String? first, String? lowest}) =>
      ChallengeAnswers(
        duel: duel ?? this.duel,
        winner: winner ?? this.winner,
        over: over ?? this.over,
        first: first ?? this.first,
        lowest: lowest ?? this.lowest,
      );

  @override
  List<Object?> get props => [duel, winner, over, first, lowest];
}

/// كل اللي فوق الماتش في التحدّي: الأنواع · اللاعيبة · إجاباتي · النتيجة ونقطي بعد الماتش.
class ChallengeExtras extends Equatable {
  const ChallengeExtras({
    this.modes = const [ChallengeMode.diff],
    this.duelA,
    this.duelB,
    this.players = const [],
    this.mine = const ChallengeAnswers(),
    this.result,
    this.points = const {},
    this.streak = 0,
  });

  final List<String> modes;
  final String? duelA, duelB;
  final List<ChallengePlayer> players; // لاعيبة الفريقين
  final ChallengeAnswers mine;

  /// بعد الماتش: winner · over · first_scorer · duel_winners · lowest.
  final Map<String, dynamic>? result;
  final Map<String, int> points; // diff · duel · quiz · lowest
  final int streak; // سلسلتي في فرق الأهداف عند الماتش ده

  bool has(String mode) => modes.contains(mode);
  int get total => points.values.fold(0, (a, b) => a + b);

  ChallengePlayer? player(String? id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<String> resultIds(String key) => [for (final x in (result?[key] as List?) ?? const []) x.toString()];

  factory ChallengeExtras.fromMap(Map<String, dynamic> m) {
    final pts = m['points'] as Map<String, dynamic>?;
    return ChallengeExtras(
      modes: [
        for (final x in (m['modes'] as List?) ?? const ['diff']) x.toString(),
      ],
      duelA: m['duel_a'] as String?,
      duelB: m['duel_b'] as String?,
      players: [
        for (final p in ((m['players'] as List?) ?? const []).cast<Map<String, dynamic>>())
          (id: p['id'].toString(), name: p['name'] as String, team: p['team'] as String, gk: p['gk'] == true),
      ],
      mine: ChallengeAnswers.fromMap(m['mine'] as Map<String, dynamic>?),
      result: m['result'] as Map<String, dynamic>?,
      points: pts == null ? const {} : {for (final k in ChallengeMode.all) k: (pts[k] as num?)?.toInt() ?? 0},
      streak: (pts?['streak'] as num?)?.toInt() ?? 0,
    );
  }

  ChallengeExtras withMine(ChallengeAnswers a) => ChallengeExtras(
    modes: modes,
    duelA: duelA,
    duelB: duelB,
    players: players,
    mine: a,
    result: result,
    points: points,
    streak: streak,
  );

  @override
  List<Object?> get props => [modes, duelA, duelB, players, mine, result, points, streak];
}
