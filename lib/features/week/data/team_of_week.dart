import 'models/week_player.dart';

/// تشكيلة الجولة = أعلى حارس جاب نقط + أعلى ٤ لاعيبة (غير الحراس) جابوا نقط.
/// لو فيه تعادل على آخر مكان من الأربعة (أو أكتر)، المتعادلين بيدخلوا تصويت، والفايزين بياخدوا الأماكن.
/// (تعادل الحراس: الأول بالاسم)
/// (نفس منطق fn_totw_tie في السيرفر)
class TeamOfWeek {
  const TeamOfWeek._({required this.sure, required this.tied, required this.openSlots});

  static const size = 5;

  /// اللي أكيد جوه (نقطهم أعلى من المتعادلين).
  final List<WeekPlayer> sure;

  /// المتعادلين على آخر الأماكن (فاضية لو مفيش تعادل).
  final List<WeekPlayer> tied;

  /// كام مكان عليه تعادل.
  final int openSlots;

  bool get hasTie => tied.isNotEmpty;

  factory TeamOfWeek.build(List<WeekPlayer> ranked) {
    final pos = ranked.where((p) => p.points > 0).toList()
      ..sort((a, b) {
        final c = b.points.compareTo(a.points);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    final gk = pos.where((p) => p.position == 'GK').take(1).toList();
    final out = pos.where((p) => p.position != 'GK').toList();
    const n = size - 1; // الأربعة اللي في الملعب
    if (out.length <= n || out[n - 1].points != out[n].points) {
      return TeamOfWeek._(sure: [...gk, ...out.take(n)], tied: const [], openSlots: 0);
    }
    final cut = out[n - 1].points;
    final sureOut = out.where((p) => p.points > cut).toList();
    return TeamOfWeek._(
      sure: [...gk, ...sureOut],
      tied: out.where((p) => p.points == cut).toList(),
      openSlots: n - sureOut.length,
    );
  }

  /// نجم الجولة = الأعلى نقط في التشكيلة.
  static WeekPlayer? starOf(Iterable<WeekPlayer?> team) {
    WeekPlayer? best;
    for (final p in team) {
      if (p != null && (best == null || p.points > best.points)) best = p;
    }
    return best;
  }

  /// الخمسة النهائيين. [winnerIds] = فايزين تصويت التعادل (بالترتيب).
  /// لو التصويت لسه/مفيش أصوات، المتعادلين بيفضلوا مكانهم فاضي (null) لحد ما يتحسم.
  List<WeekPlayer?> lineup({List<String> winnerIds = const []}) {
    final winners = [
      for (final id in winnerIds)
        for (final p in tied)
          if (p.id == id) p,
    ].take(openSlots).toList();
    final out = <WeekPlayer?>[...sure, ...winners];
    while (out.length < size && (hasTie || out.length < sure.length)) {
      out.add(null);
    }
    return out;
  }

  /// ترتيب الأماكن على الخماسي: الحارس تحت، والأعلى نقط فوق.
  /// بيرجّع ٥ أماكن: [تحت، شمال فوق، يمين فوق، شمال تحت، يمين تحت].
  static List<WeekPlayer?> arrange(List<WeekPlayer?> five) {
    final spots = List<WeekPlayer?>.filled(size, null);
    final rest = [...five];
    final gk = rest.indexWhere((p) => p?.position == 'GK');
    if (gk >= 0) spots[0] = rest.removeAt(gk);
    const order = [1, 2, 3, 4, 0]; // فوق الأول
    var i = 0;
    for (final p in rest) {
      while (i < order.length && spots[order[i]] != null) {
        i++;
      }
      if (i >= order.length) break;
      spots[order[i++]] = p;
    }
    return spots;
  }
}
