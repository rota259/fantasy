import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/prow_row.dart';
import 'leagues_widgets.dart';

/// محتوى الدوريات في وضع demo (بيانات ثابتة مطابقة للديزاين).
List<Widget> leaguesMockBody() {
  return [
    _row('🏆', 'دوري الشلّة', '8 مدراء · H2H', '1', 'st', accentTile: true, topBorder: false),
    _row('م', 'دوري المعادي', '1,240 مدير · كلاسيك', '34', ''),
    _row('ع', 'الدوري العام', '48,900 مدير', '12.5k', ''),
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text('دوري الشلّة · الترتيب', style: AppText.h(14)),
    ),
    const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(children: [
        StandingRow(rank: '1', name: 'أنت (MK)', pts: '389', me: true),
        StandingRow(rank: '2', name: 'سيف', pts: '376'),
        StandingRow(rank: '3', name: 'محمود', pts: '361'),
        StandingRow(rank: '4', name: 'أحمد', pts: '348'),
      ]),
    ),
  ];
}

Widget _row(String ini, String name, String meta, String rank, String suffix,
    {bool accentTile = false, bool topBorder = true}) {
  return ProwRow(
    topBorder: topBorder,
    leading: accentTile
        ? Container(
            width: 34, height: 34, alignment: Alignment.center,
            color: AppColors.accent,
            child: Text(ini, style: AppText.h(16, color: AppColors.white)))
        : InitialsTile(ini),
    title: name,
    subtitle: Text(meta, style: AppText.body(10, color: AppColors.neutral700)),
    trailing: Text.rich(TextSpan(children: [
      TextSpan(text: rank, style: AppText.h(16)),
      TextSpan(text: suffix, style: AppText.h(10)),
    ])),
  );
}
