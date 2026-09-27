import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../cubit/manager_match_cubit.dart';
import 'add_team_player_sheet.dart';
import '../../../core/widgets/motion.dart';

/// (مدير) تاب التشكيلة: كل فريق ٤ + حارس أساسيين و٢ احتياطي، + حفظ + إبلاغ اليوزرز.
class MatchLineupSection extends StatelessWidget {
  const MatchLineupSection({super.key, required this.match, required this.cubit, required this.state});

  final GameMatch match;
  final ManagerMatchCubit cubit;
  final ManagerMatchState state;

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /// ينفّذ عملية ويعرض رسالتها (الـ messenger بيتاخد قبل الانتظار).
  Future<void> _run(BuildContext context, Future<String> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final msg = await action();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('نزّل تشكيلة الفريقين', style: AppText.h(15)),
        const SizedBox(height: 4),
        Text(
          'كل فريق: ٤ لاعيبة + حارس أساسيين + ٢ احتياطي. لما تخلص اضغط «احفظ التشكيلة».',
          style: AppText.body(11, color: AppColors.neutral700),
        ),
        const SizedBox(height: 12),
        ..._team(context, match.teamA),
        const SizedBox(height: 18),
        ..._team(context, match.teamB),
        const SizedBox(height: 20),
        _button('💾 احفظ التشكيلة', filled: true, onTap: () => _run(context, cubit.saveLineup)),
        const SizedBox(height: 10),
        _button('🔔 أبلغ اليوزرز إن التشكيلة نزلت', onTap: () => _run(context, cubit.notifyUsers)),
      ],
    );
  }

  List<Widget> _team(BuildContext context, String team) {
    final players = state.players.where((p) => p.team == team).toList();
    final ids = players.map((p) => p.id).toSet();
    int count(String st) => state.lineup.entries.where((e) => e.value == st && ids.contains(e.key)).length;
    return [
      Row(
        children: [
          Expanded(
            child: Text(team, style: AppText.h(14, color: AppColors.accent)),
          ),
          Text(
            'أساسي ${count('starting')}/5 · احتياطي ${count('bench')}/2',
            style: AppText.body(10, color: AppColors.neutral700),
          ),
          const SizedBox(width: 8),
          Pressable(
            onTap: () async {
              final r = await showAddTeamPlayerSheet(context, team);
              if (r != null) await cubit.addPlayerToTeam(r.name, team, r.position);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: Text('+ ضيف لاعب', style: AppText.h(11)),
            ),
          ),
        ],
      ),
      if (players.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('لسه مفيش لاعيبة — اضغط "+ ضيف لاعب"', style: AppText.body(11, color: AppColors.neutral600)),
        ),
      for (final p in players) _row(context, p),
    ];
  }

  Widget _row(BuildContext context, Player p) {
    final status = state.lineup[p.id] ?? 'out';
    Widget opt(String label, String value) => Pressable(
      onTap: () {
        final err = cubit.setLineup(p.id, value);
        if (err != null) _snack(context, err);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: status == value ? AppColors.accent : null,
          border: Border.all(color: status == value ? AppColors.accent : AppColors.divider, width: 2),
        ),
        child: Text(label, style: AppText.h(10, color: status == value ? AppColors.white : AppColors.ink)),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppText.h(13)),
                Text(p.positionAr, style: AppText.body(9, color: AppColors.neutral700)),
              ],
            ),
          ),
          opt('أساسي', 'starting'),
          const SizedBox(width: 5),
          opt('احتياطي', 'bench'),
          const SizedBox(width: 5),
          opt('بره', 'out'),
        ],
      ),
    );
  }

  Widget _button(String text, {bool filled = false, required VoidCallback onTap}) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: filled ? AppColors.accent : null,
        border: filled ? null : Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Text(text, style: AppText.h(filled ? 14 : 13, color: filled ? AppColors.white : AppColors.ink)),
    ),
  );
}
