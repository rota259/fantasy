import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pill.dart';
import '../cubit/live_feed_cubit.dart';

/// بطاقة نقاط الجولة السوداء — الرقم الكبير بيعدّ مع البث الحي.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نقاط الجولة · GW POINTS',
                  style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
              const Pill.accent('DIFFERENTIAL · عمر 4%'),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: BlocBuilder<LiveFeedCubit, LiveFeedState>(
                    builder: (context, s) => Text(
                      '${s.points}',
                      style: AppText.h(96, color: AppColors.white, spacingEm: -0.04, height: 0.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Pill('▲ +12 فوق المتوسط',
                        background: AppColors.white, color: AppColors.black),
                    const SizedBox(height: 5),
                    Text('RANK 12,480 ▲3,412',
                        style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
