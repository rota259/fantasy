import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/selection_bar.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../cubit/manager_match_cubit.dart';
import 'add_team_player_sheet.dart';
import 'team_lineup_pitch.dart';

/// (مدير) تاب التشكيلة: خماسي ولا سداسي، وكل فريق على ملعبه (الأول فوق والتاني تحت).
/// دوس على مكان فاضي تختار لاعب، ودوس على لاعب تنقله احتياطي/أساسي أو تشيله أو تحذفه من الفريق.
class MatchLineupSection extends StatelessWidget {
  const MatchLineupSection({super.key, required this.match, required this.cubit, required this.state});

  final GameMatch match;
  final ManagerMatchCubit cubit;
  final ManagerMatchState state;

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

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
        Row(
          children: [
            Expanded(child: Text('الملعب', style: AppText.h(15))),
            _format(5, 'خماسي'),
            const SizedBox(width: 6),
            _format(6, 'سداسي'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'كل فريق: ${state.format} أساسيين (حارس + ${state.format - 1}) والاحتياطي اختياري — الفريق آخره ٧.',
          style: AppText.body(11, color: AppColors.neutral700),
        ),
        const SizedBox(height: 12),
        _team(context, match.teamA),
        const SizedBox(height: 18),
        _team(context, match.teamB),
        const SizedBox(height: 20),
        _button('💾 احفظ التشكيلة', filled: true, onTap: () => _run(context, cubit.saveLineup)),
        const SizedBox(height: 10),
        _button('🔔 أبلغ اليوزرز إن التشكيلة نزلت', onTap: () => _run(context, cubit.notifyUsers)),
      ],
    );
  }

  Widget _format(int f, String label) {
    final on = state.format == f;
    return Pressable(
      onTap: () => cubit.setFormat(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: on ? AppColors.accent : AppColors.card,
          borderRadius: AppRadius.md,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text('$label $f', style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
      ),
    );
  }

  Widget _team(BuildContext context, String team) {
    List<Player> inStatus(String st) => [
      for (final p in state.players)
        if (p.team == team && state.lineup[p.id] == st) p,
    ];
    return TeamLineupPitch(
      team: team,
      format: state.format,
      starters: inStatus('starting'),
      bench: inStatus('bench'),
      onSlot: (kind) => _pick(context, team, kind),
      onPlayer: (p) => _options(context, p),
    );
  }

  /// مكان فاضي: اختار من لاعيبة الفريق اللي مش في التشكيلة (الحارس للحارس) أو ضيف لاعب جديد.
  Future<void> _pick(BuildContext context, String team, String kind) async {
    final free = [
      for (final p in state.players)
        if (p.team == team &&
            !state.lineup.containsKey(p.id) &&
            (kind == 'bench' || (kind == 'gk') == (p.position == 'GK')))
          p,
    ];
    final chosen = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                kind == 'gk' ? 'الحارس — $team' : (kind == 'bench' ? 'احتياطي — $team' : 'في الملعب — $team'),
                style: AppText.h(15),
              ),
            ),
            for (final p in free)
              ListTile(
                title: Text(p.name, style: AppText.h(14)),
                subtitle: Text(p.positionAr, style: AppText.body(11)),
                onTap: () => Navigator.pop(c, p),
              ),
            ListTile(
              leading: Icon(Icons.person_add_alt, color: AppColors.accent),
              title: Text('+ ضيف لاعب جديد للفريق', style: AppText.h(13, color: AppColors.accent)),
              onTap: () => Navigator.pop(c, 'new'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || chosen == null) return;
    if (chosen == 'new') {
      final r = await showAddTeamPlayerSheet(context, team);
      if (r != null) await cubit.addPlayerToTeam(r.name, team, r.position);
      return;
    }
    final err = cubit.setLineup((chosen as Player).id, kind == 'bench' ? 'bench' : 'starting');
    if (err != null && context.mounted) _snack(context, err);
  }

  /// لاعب في التشكيلة: احتياطي ⇄ أساسي · شيله من التشكيلة · احذفه من الفريق خالص.
  Future<void> _options(BuildContext context, Player p) async {
    final starting = state.lineup[p.id] == 'starting';
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('${p.name} · ${p.positionAr}', style: AppText.h(15)),
            ),
            ListTile(
              title: Text(starting ? 'حطه احتياطي' : 'حطه أساسي', style: AppText.h(14)),
              onTap: () => Navigator.pop(c, starting ? 'bench' : 'starting'),
            ),
            ListTile(
              title: Text('شيله من التشكيلة', style: AppText.h(14)),
              onTap: () => Navigator.pop(c, 'out'),
            ),
            ListTile(
              title: Text('احذف اللاعب من الفريق', style: AppText.h(14, color: AppColors.danger)),
              onTap: () => Navigator.pop(c, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'delete') {
      final ok = await confirmBulk(context, 'حذف ${p.name}', 'هيتشال من الفريق خالص (لو لسه ملعبش ماتشات).');
      if (!ok || !context.mounted) return;
      final err = await cubit.deletePlayer(p.id);
      if (context.mounted) _snack(context, err ?? 'اتحذف ${p.name} ✓');
      return;
    }
    final err = cubit.setLineup(p.id, action);
    if (err != null && context.mounted) _snack(context, err);
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
