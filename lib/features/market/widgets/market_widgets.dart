import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/pill.dart';
import '../../../core/widgets/prow_row.dart';
import '../../players/data/models/player.dart';

/// بيانات صف لاعب في السوق.
class MarketPlayer {
  const MarketPlayer(this.ini, this.name, this.club, this.pos, this.form, this.pts, this.price,
      {this.formTag, this.accent = false, this.highlight = false});

  /// من موديل اللاعب الحقيقي (Supabase).
  factory MarketPlayer.fromPlayer(Player p) => MarketPlayer(
        p.initials,
        p.name,
        p.team,
        p.positionAr,
        'فورمة ${p.form.toStringAsFixed(1)}',
        '${p.totalPoints}',
        '${p.price.toStringAsFixed(1)}م',
        highlight: p.form >= 6,
      );

  final String ini, name, club, pos, form, pts, price;
  final String? formTag; // ▲ صاعد / ▼ مصاب
  final bool accent; // تمييز الأيقونة الأولى
  final bool highlight; // tag أخضر/رمادي
}

const marketPlayers = [
  MarketPlayer('أح', 'أحمد فتحي', 'التجمع', 'مهاجم', '▲ فورمة 8.4', '189', '8.5م', accent: true, highlight: true),
  MarketPlayer('مص', 'مصطفى وائل', 'المهندسين', 'وسط', 'فورمة 7.1', '172', '7.1م'),
  MarketPlayer('طا', 'طارق سمير', 'أكتوبر', 'مهاجم', '▲ صاعد', '141', '5.2م', highlight: true),
  MarketPlayer('كر', 'كريم حسن', 'المعادي', 'دفاع', 'فورمة 6.0', '128', '5.5م'),
  MarketPlayer('حس', 'حسام عادل', 'الرحاب', 'حارس', 'فورمة 5.3', '119', '4.8م'),
  MarketPlayer('زي', 'زياد ناصر', 'مدينة نصر', 'دفاع', '▼ مصاب', '96', '4.8م', formTag: 'hurt'),
];

/// حقل البحث.
class MarketSearch extends StatelessWidget {
  const MarketSearch({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
        child: Row(
          children: [
            const Icon(Icons.search, size: 16, color: AppColors.ink),
            const SizedBox(width: 8),
            Text('دوّر على لاعب…', style: AppText.body(12, color: AppColors.neutral600, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// شرائح المراكز + صف الترتيب.
class MarketFilters extends StatelessWidget {
  const MarketFilters({super.key});
  static const _pos = ['الكل', 'حارس', 'دفاع', 'وسط', 'هجوم'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) => i == 0
                ? Pill.accent(_pos[i])
                : Pill(_pos[i], border: AppColors.divider),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
          ),
          child: Row(
            children: [
              Text('ترتيب حسب', style: AppText.kicker()),
              const SizedBox(width: 10),
              Text('النقاط ▾', style: AppText.h(11, color: AppColors.accent)),
              const SizedBox(width: 12),
              Text('السعر', style: AppText.h(11, color: AppColors.neutral600, weight: FontWeight.w600)),
              const SizedBox(width: 12),
              Text('الفورمة', style: AppText.h(11, color: AppColors.neutral600, weight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

/// صف لاعب في السوق.
class MarketRow extends StatelessWidget {
  const MarketRow({super.key, required this.p, required this.onTap, this.onAdd, this.inSquad = false});
  final MarketPlayer p;
  final VoidCallback onTap;
  final VoidCallback? onAdd; // إضافة للفريق (null = غير مفعّل)
  final bool inSquad; // موجود بالفعل في التشكيلة

  @override
  Widget build(BuildContext context) {
    final tagColor = p.formTag == 'hurt'
        ? AppColors.neutral500
        : (p.highlight ? AppColors.accent700 : AppColors.neutral700);
    return ProwRow(
      onTap: onTap,
      leading: p.accent
          ? const InitialsTile('أح', background: AppColors.accent, color: AppColors.white)
          : InitialsTile(p.ini),
      title: p.name,
      subtitle: Text('${p.club} · ${p.pos} · ${p.form}',
          style: AppText.body(10, color: tagColor)),
      trailing: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(children: [
              Text(p.pts, style: AppText.h(15)),
              Text(p.price, style: AppText.body(9, color: AppColors.neutral700)),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: inSquad ? null : onAdd,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: inSquad ? AppColors.accent : null,
                border: Border.all(
                  color: inSquad ? AppColors.accent : AppColors.black,
                  width: 2,
                ),
              ),
              child: Text(inSquad ? '✓' : '+',
                  style: AppText.h(16, color: inSquad ? AppColors.white : AppColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}
