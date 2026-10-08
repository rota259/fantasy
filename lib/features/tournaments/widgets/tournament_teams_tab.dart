import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../cubit/tournament_cubit.dart';
import 'draw_animation.dart';
import 'register_team_sheet.dart';

/// الفرق: المقبولين (بمجموعاتهم) · الطلبات (للمنظّم) · ضيف فريق · القرعة — واليوزر يسجّل فريقه.
class TournamentTeamsTab extends StatefulWidget {
  const TournamentTeamsTab({super.key, required this.state, required this.runs});
  final TournamentState state;
  final bool runs; // أنا اللي بدير البطولة

  @override
  State<TournamentTeamsTab> createState() => _TournamentTeamsTabState();
}

class _TournamentTeamsTabState extends State<TournamentTeamsTab> {
  final _team = TextEditingController();

  @override
  void dispose() {
    _team.dispose();
    super.dispose();
  }

  void _msg(String? err, String ok) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? ok)));

  Future<void> _draw() async {
    final cubit = context.read<TournamentCubit>();
    final err = await cubit.draw();
    if (!mounted) return;
    if (err != null) return _msg(err, '');
    final s = cubit.state;
    final cols = <String, List<String>>{};
    if (s.tournament?.format == 'groups') {
      for (final t in s.approved) {
        cols.putIfAbsent('مجموعة ${t.group ?? '?'}', () => []).add(t.team);
      }
    } else if (s.tournament?.format == 'knockout') {
      final first = s.bracket.where((b) => b.round == 1).toList();
      for (var k = 0; k < first.length; k += 2) {
        cols['ماتش ${k ~/ 2 + 1}'] = [first[k].team ?? 'راحة', if (k + 1 < first.length) first[k + 1].team ?? 'راحة'];
      }
    } else {
      cols['الدوري'] = [for (final t in s.approved) t.team];
    }
    await showDrawAnimation(context, cols);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final t = s.tournament!;
    final cubit = context.read<TournamentCubit>();
    final reg = t.isRegistration;
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('الفرق (${s.approved.length}/${t.teamCount})', style: AppText.h(15)),
        ),
        if (widget.runs && reg) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _team,
                    decoration: const InputDecoration(hintText: 'اسم فريق'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final err = await cubit.addTeam(_team.text.trim());
                    if (err == null) _team.clear();
                    _msg(err, 'اتضاف ✓');
                  },
                  child: const Text('ضيف'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.black),
              onPressed: s.approved.length < 2 ? null : _draw,
              icon: const Icon(Icons.casino_outlined),
              label: const Text('🎲 اعمل القرعة والجدول'),
            ),
          ),
        ],
        if (!widget.runs && reg)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: OutlinedButton.icon(
              onPressed: () => showRegisterTeamSheet(context, cubit),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('سجّل فريقك في البطولة'),
            ),
          ),
        if (widget.runs && s.pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text('طلبات المشاركة (${s.pending.length})', style: AppText.h(14, color: AppColors.info)),
          ),
          for (final p in s.pending)
            Container(
              margin: AppDecor.tileMargin,
              padding: const EdgeInsets.all(12),
              decoration: AppDecor.tile,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.team, style: AppText.h(14)),
                        Text([p.phone, p.note].whereType<String>().join(' · '), style: AppText.body(11)),
                      ],
                    ),
                  ),
                  if (p.phone != null)
                    IconButton(onPressed: () => Launchers.call(p.phone!), icon: const Icon(Icons.call_outlined)),
                  IconButton(
                    onPressed: () async => _msg(await cubit.reviewTeam(p.team, true), 'اتقبل ✓'),
                    icon: Icon(Icons.check_circle, color: AppColors.accent),
                  ),
                  IconButton(
                    onPressed: () async => _msg(await cubit.reviewTeam(p.team, false), 'اترفض'),
                    icon: Icon(Icons.cancel_outlined, color: AppColors.danger),
                  ),
                ],
              ),
            ),
        ],
        for (final team in s.approved)
          Container(
            margin: AppDecor.tileMargin,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: AppDecor.tile,
            child: Row(
              children: [
                const Text('🛡'),
                const SizedBox(width: 10),
                Expanded(child: Text(team.team, style: AppText.h(14))),
                if (team.group != null) Text('مجموعة ${team.group}', style: AppText.h(11, color: AppColors.info)),
              ],
            ),
          ),
      ],
    );
  }
}
