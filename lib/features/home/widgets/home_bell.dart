import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../notifications/cubit/notifications_badge_cubit.dart';
import '../../notifications/data/notifications_repository.dart';
import '../../notifications/view/notifications_screen.dart';

/// جرس الإشعارات + عدّاد اللي متشافش.
class HomeBell extends StatelessWidget {
  const HomeBell({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final repo = context.read<NotificationsRepository>();
        context.read<NotificationsBadgeCubit>().markSeen();
        Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(repo: repo)));
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: AppColors.white, width: 2)),
            child: const Icon(Icons.notifications_none, size: 18, color: AppColors.white),
          ),
          BlocBuilder<NotificationsBadgeCubit, int>(
            builder: (context, count) {
              if (count <= 0) return const SizedBox.shrink();
              return Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  alignment: Alignment.center,
                  color: AppColors.danger,
                  child: Text(count > 99 ? '99+' : '$count', style: AppText.h(9, color: AppColors.white)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// لوجو الهوم: رقم 5 جوه خماسي أبيض.
class HomeLogo extends StatelessWidget {
  const HomeLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.only(top: 4),
      alignment: Alignment.center,
      decoration: const ShapeDecoration(color: AppColors.white, shape: StarBorder.polygon(sides: 5)),
      child: Text('5', style: AppText.h(18, color: AppColors.accent)),
    );
  }
}
