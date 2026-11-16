import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';

/// (كابتن) تشكيلة فريقي للماتش: كل لاعب أساسي / احتياطي / مش جاي → بتتبعت للمدير يطبّقها.
Future<bool?> showCaptainLineupSheet(BuildContext context, GameMatch match, String team) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.bg,
  builder: (_) => _Sheet(match: match, team: team),
);

class _Sheet extends StatefulWidget {
  const _Sheet({required this.match, required this.team});
  final GameMatch match;
  final String team;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late final Future<List<Player>> _players = context.read<PlayersRepository>().fetchByTeams([widget.team]);
  final Map<String, String> _sel = {}; // playerId → starting | bench
  bool _busy = false;

  int get _format => widget.match.format;

  Future<void> _send(List<Player> all) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final starters = all.where((p) => _sel[p.id] == 'starting').toList();
    final gk = starters.where((p) => p.position == 'GK').length;
    String? err;
    if (starters.length != _format) err = 'لازم $_format أساسيين';
    if (err == null && gk != 1) err = 'لازم حارس واحد في الأساسيين';
    if (err == null && _sel.length > 7) err = 'الفريق آخره ٧';
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<LineupRepository>().submitTeam(widget.match.id, _sel);
      messenger.showSnackBar(const SnackBar(content: Text('التشكيلة اتبعتت للمدير ✓')));
      nav.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _choice(Player p, String? v, String label) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: ChoiceChip(
      label: Text(label, style: AppText.body(11)),
      visualDensity: VisualDensity.compact,
      selected: _sel[p.id] == v,
      onSelected: (_) => setState(() => v == null ? _sel.remove(p.id) : _sel[p.id] = v),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
    child: FutureBuilder<List<Player>>(
      future: _players,
      builder: (context, snap) {
        final all = snap.data;
        if (all == null) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        final starters = _sel.values.where((v) => v == 'starting').length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('تشكيلة ${widget.team}', style: AppText.h(18)),
            Text(
              '${widget.match.teamA} ضد ${widget.match.teamB} — $_format أساسيين (حارس + ${_format - 1}) والفريق آخره ٧. '
              'المدير هيطبّقها وينزّلها للناس.',
              style: AppText.body(12, color: AppColors.neutral700),
            ),
            const SizedBox(height: 6),
            Text('أساسي: $starters/$_format · كله: ${_sel.length}/٧', style: AppText.h(12, color: AppColors.accent)),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (all.isEmpty) Text('ضيف لاعيبة فريقك الأول', style: AppText.body(12)),
                  for (final p in all)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.shortName}${p.position == 'GK' ? ' 🧤' : ''}',
                              style: AppText.h(13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _choice(p, 'starting', 'أساسي'),
                          _choice(p, 'bench', 'احتياطي'),
                          _choice(p, null, 'مش جاي'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : () => _send(all),
              child: Text(_busy ? '...' : 'ابعت التشكيلة للمدير'),
            ),
          ],
        );
      },
    ),
  );
}
