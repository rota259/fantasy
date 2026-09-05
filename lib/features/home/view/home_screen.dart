import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/prow_row.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_bar.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/home_feed.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_shortcuts.dart';
import '../widgets/home_squad.dart';

/// تبويب الرئيسية — مركز يوم الماتش.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Column(
      children: [
        const StatusArea(),
        Masthead(
          title: 'الخماسي',
          subtitle: 'MATCHDAY 07 · دوري القاهرة',
          titleLeading: _logoTile(),
          trailing: _liveBadge(),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const HomeHero(),
              const HomeFeed(),
              HomeShortcuts(onOpen: nav.openOverlay),
              HomeSquad(onEdit: () => nav.setTab(AppTab.team)),
              const SectionHeader(
                title: 'أبرز نجوم الجولة',
                kicker: 'TOP OF GW7',
                padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
              ),
              ..._topPerformers(nav),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logoTile() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      color: AppColors.white,
      child: Text('٥', style: AppText.h(18, color: AppColors.accent)),
    );
  }

  Widget _liveBadge() {
    return Transform.rotate(
      angle: -6 * 3.1416 / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(border: Border.all(color: AppColors.white, width: 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BlinkDot(color: AppColors.white),
            const SizedBox(width: 5),
            Text('LIVE', style: AppText.h(10, color: AppColors.white, spacingEm: 0.14)),
          ],
        ),
      ),
    );
  }

  List<Widget> _topPerformers(AppNavCubit nav) {
    Widget sub(String t) => Text(t, style: AppText.body(10, color: AppColors.neutral700));
    return [
      ProwRow(
        topBorder: false,
        onTap: () => nav.openPlayer(null),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 16, child: Text('1', style: AppText.h(13, color: AppColors.accent))),
          const SizedBox(width: 6),
          const InitialsTile('أح', background: AppColors.accent, color: AppColors.white),
        ]),
        title: 'أحمد فتحي',
        subtitle: sub('التجمع · مهاجم · 8.4م'),
        trailing: Text('31', style: AppText.h(20)),
      ),
      ProwRow(
        onTap: () => nav.openPlayer(null),
        leading: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 16, child: Text('2', style: AppText.h(13, color: AppColors.neutral500))),
          const SizedBox(width: 6),
          const InitialsTile('مص'),
        ]),
        title: 'مصطفى وائل',
        subtitle: sub('المهندسين · وسط · 7.1م'),
        trailing: Text('27', style: AppText.h(20)),
      ),
    ];
  }
}
