import '../players/data/availability.dart';
import '../players/data/models/player.dart';
import '../players/data/models/player_gw_stat.dart';

/// عنصر في قايمة المدرّب: لاعب + القيمة اللي بتميّزه.
typedef CoachItem = ({Player player, String value});

/// قسم في تقرير المدرّب.
class CoachSection {
  const CoachSection(this.title, this.hint, this.items);
  final String title;
  final String hint;
  final List<CoachItem> items;
}

/// تقرير المدرّب الكامل.
class CoachReport {
  const CoachReport({this.captain, this.captainReason = '', this.sections = const []});
  final Player? captain;
  final String captainReason;
  final List<CoachSection> sections;
}

/// محرّك المدرّب بالقواعد — بيبني النصايح من الداتا الموجودة (من غير AI).
abstract final class CoachEngine {
  CoachEngine._();

  static CoachReport build({
    required List<Player> players,
    required Map<String, PlayerGwStat> stats,
    List<String> nextTeams = const [],
  }) {
    PlayerGwStat st(Player p) => stats[p.id] ?? PlayerGwStat(playerId: p.id);
    final ready = players.where((p) => p.availability == Availability.ready).toList();

    // الكابتن: من لاعيبة الماتش الجاي (لو موجود)، جاهز، أعلى (فورمة×٢ + نقاط الجولة).
    final pool = nextTeams.isEmpty ? ready : ready.where((p) => nextTeams.contains(p.team)).toList();
    double score(Player p) => p.form * 2 + st(p).points + p.totalPoints / 20;
    final capList = [...pool]..sort((a, b) => score(b).compareTo(score(a)));
    final cap = capList.isEmpty || score(capList.first) <= 0 ? null : capList.first;

    List<CoachItem> top(Iterable<Player> src, num Function(Player) key, String Function(Player) label) {
      final l = src.where((p) => key(p) > 0).toList()..sort((a, b) => key(b).compareTo(key(a)));
      return [for (final p in l.take(3)) (player: p, value: label(p))];
    }

    final sections = [
      CoachSection(
        'في الفورمة 🔥',
        'أعلى متوسط نقاط في آخر ٣ جولات',
        top(ready, (p) => p.form, (p) => 'فورمة ${p.form.toStringAsFixed(1)}'),
      ),
      CoachSection(
        'نجوم الجولة ⭐',
        'أعلى نقاط في الجولة',
        top(players, (p) => st(p).points, (p) => '${st(p).points} نقطة'),
      ),
      CoachSection(
        'جواهر مخفية 💎',
        'فورمة حلوة وامتلاك قليل (أقل من ٢٠٪)',
        top(
          ready.where((p) => st(p).ownership < 20),
          (p) => p.form,
          (p) => '${st(p).ownership.toStringAsFixed(0)}% امتلاك',
        ),
      ),
      CoachSection(
        'الأكثر امتلاكًا 👥',
        'أكتر لاعيبة الناس مختارينها',
        top(players, (p) => st(p).ownership, (p) => '${st(p).ownership.toStringAsFixed(1)}%'),
      ),
      CoachSection(
        'الأكثر دخولًا ↗',
        'الناس بتختارهم الجولة دي',
        top(players, (p) => st(p).transfersIn, (p) => '+${st(p).transfersIn}'),
      ),
      CoachSection(
        'الأكثر خروجًا ↘',
        'الناس بتشيلهم الجولة دي',
        top(players, (p) => st(p).transfersOut, (p) => '-${st(p).transfersOut}'),
      ),
      CoachSection('تجنّبهم ⚠️', 'مصابين / مشكوك فيهم / موقوفين', [
        for (final p in players.where((p) => p.availability != Availability.ready).take(5))
          (player: p, value: Availability.label(p.availability)),
      ]),
    ].where((s) => s.items.isNotEmpty).toList();

    return CoachReport(
      captain: cap,
      captainReason: cap == null ? '' : 'جاهز · فورمة ${cap.form.toStringAsFixed(1)} · إجمالي ${cap.totalPoints} نقطة',
      sections: sections,
    );
  }
}
