import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../week/data/models/week_player.dart';

/// أبرز نجوم الجولة: أعلى ٥ في الجولة (مباشر لحد الجمعة 4 الفجر ثم نهائي) أو أعلى ٥ النهارده.
class HomeStars extends StatefulWidget {
  const HomeStars({
    super.key,
    required this.week,
    required this.today,
    required this.weekFinal,
    required this.weekLabel,
  });

  final List<WeekPlayer> week;
  final List<WeekPlayer> today;
  final bool weekFinal;
  final String weekLabel;

  @override
  State<HomeStars> createState() => _HomeStarsState();
}

class _HomeStarsState extends State<HomeStars> {
  bool _today = false;

  @override
  Widget build(BuildContext context) {
    final list = _today ? widget.today : widget.week;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
        child: Row(children: [
          Expanded(child: Text('أبرز نجوم الجولة', style: AppText.h(17))),
          _chip('الجولة', !_today, () => setState(() => _today = false)),
          const SizedBox(width: 6),
          _chip('النهارده', _today, () => setState(() => _today = true)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(children: [
          if (!_today)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: widget.weekFinal ? AppColors.black : AppColors.danger,
              child: Text(widget.weekFinal ? 'النهائي ✓' : '● مباشر',
                  style: AppText.h(10, color: AppColors.white)),
            ),
          if (!_today) const SizedBox(width: 6),
          Expanded(
            child: Text(
              _today ? 'أعلى ٥ جابوا نقط النهارده' : widget.weekLabel,
              style: AppText.body(10, color: AppColors.neutral600),
            ),
          ),
        ]),
      ),
      if (list.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(_today ? 'محدش جاب نقط النهارده لسه' : 'لسه مفيش نقاط في الجولة دي',
              style: AppText.body(12, color: AppColors.neutral600)),
        ),
      for (var i = 0; i < list.length; i++) _row(i + 1, list[i]),
    ]);
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? AppColors.black : null,
            border: Border.all(color: AppColors.black, width: 2),
          ),
          child: Text(label, style: AppText.h(11, color: on ? AppColors.white : AppColors.ink)),
        ),
      );

  Widget _row(int rank, WeekPlayer p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        SizedBox(width: 22, child: Text('$rank', style: AppText.h(14, color: AppColors.accent))),
        InitialsTile(p.initials, background: AppColors.accent, color: AppColors.white),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: AppText.h(14)),
            Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
          ]),
        ),
        Text('${p.points}', style: AppText.h(20)),
      ]),
    );
  }
}
