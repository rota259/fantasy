import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';
import '../../week/data/week_window.dart';
import '../data/admin_repository.dart';
import '../../../core/widgets/fx/skeleton.dart';

typedef _Stats = ({AdminCounts counts, List<AppUser> top, int nextPicks, int managersActive});

/// (أدمن) أرقام سريعة من السيرفر (من غير ما نحمّل كل اليوزرز واللاعيبة): المستخدمين، اللاعيبة، الماتشات،
/// تشكيلات الجولة الجاية، وأعلى ٥.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late final Future<_Stats> _future = _load();

  Future<_Stats> _load() async {
    final admin = context.read<AdminRepository>();
    final (counts, top, picks) = await (
      admin.counts(),
      admin.fetchUsers(role: 'user', limit: 5),
      admin.roundPickerCount(WeekWindow.open().cutoff),
    ).wait;
    return (counts: counts, top: top, nextPicks: picks, managersActive: counts.managers);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Stats>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Padding(padding: EdgeInsets.all(20), child: const SkeletonList());
        }
        final s = snap.data!;
        return Container(
          decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _stat('${s.counts.users}', 'يوزر'),
                  _stat('${s.counts.players}', 'لاعب'),
                  _stat('${s.counts.upcoming}', 'ماتش جاي'),
                  _stat('${s.counts.finished}', 'خلص'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'تشكيلات الجولة الجاية: ${s.nextPicks} من ${s.counts.users} · ${s.managersActive} مدير منطقة',
                style: AppText.h(12, color: AppColors.accent400),
              ),
              if (s.top.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('أعلى ٥', style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
                const SizedBox(height: 4),
                for (var i = 0; i < s.top.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text('${i + 1}', style: AppText.h(12, color: AppColors.accent400)),
                        ),
                        Expanded(
                          child: Text(s.top[i].name, style: AppText.body(12, color: AppColors.white)),
                        ),
                        Text('${s.top[i].totalPoints}', style: AppText.h(12, color: AppColors.white)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      children: [
        Text(value, style: AppText.h(24, color: AppColors.white)),
        Text(label, style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.6))),
      ],
    ),
  );
}
