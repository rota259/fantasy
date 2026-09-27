import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/widgets/match_format.dart';
import '../cubit/notifications_cubit.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_repository.dart';
import '../../../core/widgets/motion.dart';

/// صندوق الإشعارات لكل اليوزرز (اللي المدير بيبعتها).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.repo});

  final NotificationsRepository repo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(repo)..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(title: 'الإشعارات', subtitle: 'NOTIFICATIONS', onBack: () => Navigator.pop(context)),
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, s) {
                  if (s.isLoading) {
                    return Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }
                  if (s.items.isEmpty) {
                    return Center(
                      child: Text('لسه مفيش إشعارات', style: AppText.body(13, color: AppColors.neutral600)),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () => context.read<NotificationsCubit>().load(),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [for (final (i, n) in s.items.indexed) FadeSlideIn(index: i, child: _row(n))],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(AppNotification n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            color: AppColors.accent,
            child: Icon(Icons.notifications, size: 18, color: AppColors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title, style: AppText.h(14)),
                if (n.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.body, style: AppText.body(11, color: AppColors.neutral700)),
                ],
                const SizedBox(height: 3),
                Text(
                  '${arabicWeekday(n.createdAt)} ${arabicTime(n.createdAt)}',
                  style: AppText.body(9, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
