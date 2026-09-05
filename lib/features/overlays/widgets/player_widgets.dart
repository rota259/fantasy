import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fdr_chip.dart';
import '../../../core/widgets/pill.dart';
import '../../players/data/models/player.dart';

/// ترويسة اللاعب السوداء (أفاتار + اسم + شارات).
class PlayerHeader extends StatelessWidget {
  const PlayerHeader({super.key, required this.onBack, this.player});
  final VoidCallback onBack;
  final Player? player;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final ini = p?.initials ?? 'أح';
    final name = p?.name ?? 'أحمد فتحي';
    final meta = p != null ? '${p.team} · ${p.positionAr}' : 'التجمع · مهاجم · #9';
    final price = p != null ? '${p.price.toStringAsFixed(1)}م' : '8.5م';

    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 30, height: 30, alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2)),
              child: Text('‹', style: AppText.h(16, color: AppColors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 66, height: 66, alignment: Alignment.center,
              color: AppColors.accent,
              child: Text(ini, style: AppText.h(24, color: AppColors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.h(24, color: AppColors.white, height: 1)),
                  const SizedBox(height: 3),
                  Text(meta,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 8),
                  Row(children: [
                    Pill.accent(price),
                    if (p == null) ...[
                      const SizedBox(width: 8),
                      Pill('ملكية 31%', background: AppColors.white.withValues(alpha: 0.15), color: AppColors.white),
                    ],
                  ]),
                ],
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// شبكة 3×2 لإحصائيات اللاعب.
class PlayerStatGrid extends StatelessWidget {
  const PlayerStatGrid({super.key, this.player});
  final Player? player;

  static const _mock = [
    ('189', 'إجمالي النقاط', false), ('8.4', 'الفورمة', true), ('14', 'أهداف', false),
    ('7', 'صناعة', false), ('31', 'نقاط الجولة', false), ('×2.1', 'نقاط/مليون', false),
  ];

  List<(String, String, bool)> get _stats {
    final p = player;
    if (p == null) return _mock;
    final ratio = p.price > 0 ? '×${(p.totalPoints / p.price).toStringAsFixed(1)}' : '—';
    return [
      ('${p.totalPoints}', 'إجمالي النقاط', false),
      (p.form.toStringAsFixed(1), 'الفورمة', true),
      ('${p.goals}', 'أهداف', false),
      ('${p.assists}', 'صناعة', false),
      ('${p.cleanSheets}', 'شباك نظيفة', false),
      (ratio, 'نقاط/مليون', false),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 2))),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.7,
        children: _stats.map((s) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.divider),
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.$1, style: AppText.h(22, color: s.$3 ? AppColors.accent : AppColors.ink)),
                Text(s.$2, style: AppText.body(9, color: AppColors.neutral700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// رسم أعمدة آخر 5 جولات.
class PlayerLast5 extends StatelessWidget {
  const PlayerLast5({super.key});
  static const _bars = [
    (38.0, '6', AppColors.neutral300), (52.0, '9', AppColors.neutral400),
    (24.0, '4', AppColors.neutral300), (66.0, '13', AppColors.accent500),
    (78.0, '31', AppColors.accent),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider, width: 2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final b in _bars)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(height: b.$1, width: double.infinity, color: b.$3),
                    const SizedBox(height: 4),
                    Text(b.$2, style: AppText.h(9)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// كروت الماتشات الجاية بشارات FDR.
class PlayerNextFixtures extends StatelessWidget {
  const PlayerNextFixtures({super.key});
  static const _fx = [('GW8', 'ضد أكتوبر', 2), ('GW9', 'ضد المعادي', 3), ('GW10', 'ضد التجمع', 5)];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Row(
        children: [
          for (var i = 0; i < _fx.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                child: Column(children: [
                  Text(_fx[i].$1, style: AppText.body(10, color: AppColors.neutral700)),
                  const SizedBox(height: 3),
                  Text(_fx[i].$2, style: AppText.h(12)),
                  const SizedBox(height: 3),
                  FdrChip(_fx[i].$3),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
