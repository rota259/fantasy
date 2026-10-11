import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../challenge/data/models/challenge_extras.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';

typedef ChallengeSetup = ({List<String> modes, String? duelA, String? duelB});

/// المدير بيختار أنواع التحدّي للماتش: واحد أو أكتر أو الأربعة — و«مين فيهم؟» محتاج لاعب من كل فريق.
Future<ChallengeSetup?> showChallengeSetupSheet(BuildContext context, GameMatch m) =>
    showModalBottomSheet<ChallengeSetup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      builder: (_) => _SetupSheet(match: m),
    );

class _SetupSheet extends StatefulWidget {
  const _SetupSheet({required this.match});
  final GameMatch match;

  @override
  State<_SetupSheet> createState() => _SetupSheetState();
}

class _SetupSheetState extends State<_SetupSheet> {
  late final Future<List<Player>> _players = context.read<PlayersRepository>().fetchAll();
  final _modes = <String>{ChallengeMode.diff};
  String? _a, _b;

  void _submit() {
    final messenger = ScaffoldMessenger.of(context);
    if (_modes.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('اختار نوع تحدّي واحد على الأقل')));
      return;
    }
    final duel = _modes.contains(ChallengeMode.duel);
    if (duel && (_a == null || _b == null)) {
      messenger.showSnackBar(const SnackBar(content: Text('«مين فيهم؟» محتاج لاعب من كل فريق')));
      return;
    }
    Navigator.pop(context, (
      modes: [
        for (final k in ChallengeMode.all)
          if (_modes.contains(k)) k,
      ],
      duelA: duel ? _a : null,
      duelB: duel ? _b : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final all = _modes.length == ChallengeMode.all.length;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('تحدّي ${m.teamA} ضد ${m.teamB}', style: AppText.h(16))),
                TextButton(
                  onPressed: () => setState(() {
                    all ? _modes.removeAll(ChallengeMode.all) : _modes.addAll(ChallengeMode.all);
                  }),
                  child: Text(all ? 'شيل الكل' : 'الأربعة'),
                ),
              ],
            ),
            Text(
              'اختار نوع واحد أو أكتر — هيتبعت إشعار ليوزرز المنطقة.',
              style: AppText.body(12, color: AppColors.neutral700),
            ),
            for (final k in ChallengeMode.all)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _modes.contains(k),
                onChanged: (on) => setState(() => on == true ? _modes.add(k) : _modes.remove(k)),
                secondary: Icon(ChallengeMode.icon(k), color: AppColors.accent),
                title: Text(ChallengeMode.label(k), style: AppText.h(14)),
                subtitle: Text(ChallengeMode.hint(k), style: AppText.body(11, color: AppColors.neutral700)),
              ),
            if (_modes.contains(ChallengeMode.duel))
              FutureBuilder<List<Player>>(
                future: _players,
                builder: (context, snap) {
                  if (!snap.hasData) return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
                  return Column(
                    children: [
                      _pick(snap.data!, m.teamA, _a, (v) => setState(() => _a = v)),
                      const SizedBox(height: 8),
                      _pick(snap.data!, m.teamB, _b, (v) => setState(() => _b = v)),
                    ],
                  );
                },
              ),
            const SizedBox(height: 14),
            FilledButton(onPressed: _submit, child: const Text('أعلن التحدّي')),
          ],
        ),
      ),
    );
  }

  Widget _pick(List<Player> players, String team, String? value, ValueChanged<String?> onChanged) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(hintText: 'لاعب من $team', isDense: true),
        items: [
          for (final p in players.where((p) => p.team == team))
            DropdownMenuItem(value: p.id, child: Text('${p.name}${p.position == 'GK' ? ' 🧤' : ''}')),
        ],
        onChanged: onChanged,
      );
}
