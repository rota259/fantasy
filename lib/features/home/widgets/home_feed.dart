import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/blink_dot.dart';
import '../cubit/live_feed_cubit.dart';

/// البث الحي: صفوف بتتكشف من تحت لفوق، الأحدث فوق.
class HomeFeed extends StatelessWidget {
  const HomeFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.night2,
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 8),
            child: Row(
              children: [
                const BlinkDot(color: AppColors.accent),
                const SizedBox(width: 8),
                Text('بث النقاط الحي', style: AppText.h(13, color: AppColors.white)),
                const SizedBox(width: 8),
                Text('LIVE FEED',
                    style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
          BlocBuilder<LiveFeedCubit, LiveFeedState>(
            builder: (context, s) {
              final shown = s.events.take(s.count).toList().reversed.toList();
              if (shown.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('لسه مفيش أحداث في الجولة',
                      style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.5))),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    _row(shown[i], hot: i == 0),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(FeedEvent e, {required bool hot}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: hot ? AppColors.accent.withValues(alpha: 0.18) : null,
        border: const Border(top: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(e.min, style: AppText.h(12, color: AppColors.accent400))),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            color: AppColors.white,
            child: Text(e.ini, style: AppText.h(12, color: AppColors.black)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.who, style: AppText.h(13, color: AppColors.white)),
                Text(e.act,
                    style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Text(e.pts >= 0 ? '+${e.pts}' : '${e.pts}',
              style: AppText.h(17, color: AppColors.accent400)),
        ],
      ),
    );
  }
}
