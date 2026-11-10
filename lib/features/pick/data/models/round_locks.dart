import 'dart:math';

import 'package:equatable/equatable.dart';

/// قفل الجولة لكل لاعب + عدّ التغييرات (من my_round_state في السيرفر — نفس القواعد).
///   • كل لاعب بيتقفل قبل أول ماتش لفريقه في الجولة بساعة — اللي اتقفل ميتشالش ولا يدخل ولا يتغيّر مكانه.
///   • التغيير = لاعب في تشكيلة الجولة مش موجود في تشكيلة الجولة اللي فاتت.
///   • [free] = المجاني في الجولة دي: كل جولة بتزوّد واحد، واللي متستخدمش بيتجمّع (آخره ٥) — والزيادة −٤.
///   • الوايلد كارد: كل التغييرات ببلاش · أول تشكيلة في حياتك (مفيش جولة قبلها): ببلاش.
class RoundLocks extends Equatable {
  const RoundLocks({this.lockAt = const {}, this.baseline, this.wildcard = false, this.free = 1, this.hit = 4});

  /// playerId → إمتى بيتقفل (اللي مش موجود: ملوش ماتش في الجولة لسه).
  final Map<String, DateTime> lockAt;

  /// تشكيلة الجولة اللي فاتت (null = مفيش = كل حاجة ببلاش).
  final Set<String>? baseline;
  final bool wildcard;
  final int free, hit;

  factory RoundLocks.fromMap(Map<String, dynamic> m) => RoundLocks(
    lockAt: {
      for (final e in Map<String, dynamic>.from((m['locks'] as Map?) ?? const {}).entries)
        e.key: DateTime.parse('${e.value}').toLocal(),
    },
    baseline: m['baseline'] == null ? null : {for (final id in m['baseline'] as List) '$id'},
    wildcard: (m['wildcard'] ?? false) as bool,
    free: (m['free'] as num?)?.toInt() ?? 1,
    hit: (m['hit'] as num?)?.toInt() ?? 4,
  );

  bool isLocked(String playerId, [DateTime? now]) {
    final at = lockAt[playerId];
    return at != null && !(now ?? DateTime.now()).isBefore(at);
  }

  /// كام لاعب في التشكيلة دي مكانوش في تشكيلة الجولة اللي فاتت.
  int transfers(Iterable<String> ids) => baseline == null ? 0 : ids.where((id) => !baseline!.contains(id)).length;

  /// خصم التغييرات من نقط الجولة.
  int cost(int transfers) => wildcard ? 0 : hit * max(transfers - free, 0);

  @override
  List<Object?> get props => [lockAt, baseline, wildcard, free, hit];
}
