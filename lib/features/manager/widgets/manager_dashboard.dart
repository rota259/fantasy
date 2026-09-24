import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/players_repository.dart';
import '../data/admin_repository.dart';

typedef _Stats = ({
  List<AppUser> users,
  int players,
  int upcoming,
  int finished,
  GameMatch? next,
  int nextPicks,
});

/// (مدير) أرقام سريعة: المستخدمين، اللاعيبة، الماتشات، تشكيلات الماتش الجاي، وأعلى ٥.
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  late final Future<_Stats> _future = _load();

  Future<_Stats> _load() async {
    final admin = context.read<AdminRepository>();
    final matchesRepo = context.read<MatchesRepository>();
    final players = await context.read<PlayersRepository>().fetchAll();
    final users = (await admin.fetchUsers()).where((u) => !u.isManager).toList();
    final all = await matchesRepo.fetchAll();
    final upcoming = all.where((m) => !m.isFinished).toList();
    final next = upcoming.isEmpty ? null : upcoming.first;
    final picks = next == null ? 0 : (await admin.pickedUserIds(next.id)).length;
    return (
      users: users,
      players: players.length,
      upcoming: upcoming.length,
      finished: all.length - upcoming.length,
      next: next,
      nextPicks: picks,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Stats>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final s = snap.data!;
        return Container(
          color: AppColors.black,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stat('${s.users.length}', 'يوزر'),
              _stat('${s.players}', 'لاعب'),
              _stat('${s.upcoming}', 'ماتش جاي'),
              _stat('${s.finished}', 'خلص'),
            ]),
            if (s.next != null) ...[
              const SizedBox(height: 12),
              Text('${s.next!.teamA} ضد ${s.next!.teamB}: نزّل تشكيلته ${s.nextPicks} من ${s.users.length}',
                  style: AppText.h(12, color: AppColors.accent400)),
            ],
            if (s.users.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('أعلى ٥', style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
              const SizedBox(height: 4),
              for (var i = 0; i < s.users.length && i < 5; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    SizedBox(width: 20, child: Text('${i + 1}', style: AppText.h(12, color: AppColors.accent400))),
                    Expanded(child: Text(s.users[i].name, style: AppText.body(12, color: AppColors.white))),
                    Text('${s.users[i].totalPoints}', style: AppText.h(12, color: AppColors.white)),
                  ]),
                ),
            ],
          ]),
        );
      },
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(children: [
          Text(value, style: AppText.h(24, color: AppColors.white)),
          Text(label, style: AppText.body(10, color: AppColors.white.withValues(alpha: 0.6))),
        ]),
      );
}
