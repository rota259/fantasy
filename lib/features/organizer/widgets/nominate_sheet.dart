import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../awards/data/video_link.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../polls/data/polls_repository.dart';

/// ترشيح من ماتش: هدف ولا تصدّي · اللاعب (من تشكيلة الماتش) · لينك الفيديو. بيرجّع true لو اترشّح.
Future<bool?> showNominateSheet(BuildContext context, GameMatch m) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.bg,
  builder: (_) => _NominateSheet(match: m),
);

class _NominateSheet extends StatefulWidget {
  const _NominateSheet({required this.match});
  final GameMatch match;

  @override
  State<_NominateSheet> createState() => _NominateSheetState();
}

class _NominateSheetState extends State<_NominateSheet> {
  late final Future<List<Player>> _players = _load();
  final _link = TextEditingController();
  String _kind = 'goal';
  String? _playerId;
  bool _busy = false;

  /// لاعيبة تشكيلة الماتش بس.
  Future<List<Player>> _load() async {
    final (lineup, all) = await (
      context.read<LineupRepository>().fetchForMatch(widget.match.id),
      context.read<PlayersRepository>().fetchAll(),
    ).wait;
    final ids = {for (final l in lineup) l.playerId};
    return all.where((p) => ids.contains(p.id)).toList()..sort((a, b) => a.team.compareTo(b.team));
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    if (_playerId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('اختار اللاعب')));
      return;
    }
    if (!VideoLink.isValid(_link.text)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('حط لينك فيديو (يوتيوب · تيك توك · إنستجرام · فيسبوك · درايف)')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<PollsRepository>().nominate(_kind, widget.match.id, _playerId!, _link.text);
      messenger.showSnackBar(const SnackBar(content: Text('اترشّح ✓ — بقى في تصويت الجولة')));
      nav.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
      child: FutureBuilder<List<Player>>(
        future: _players,
        builder: (context, snap) {
          final players = snap.data ?? const <Player>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('رشّح من ${m.teamA} ضد ${m.teamB}', style: AppText.h(16)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'goal', label: Text('هدف ⚽')),
                  ButtonSegment(value: 'save', label: Text('تصدّي 🧤')),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
              const SizedBox(height: 12),
              if (snap.connectionState != ConnectionState.done)
                const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
              else if (players.isEmpty)
                Text('الماتش ده مالوش تشكيلة', style: AppText.body(12, color: AppColors.danger))
              else
                DropdownButtonFormField<String>(
                  initialValue: _playerId,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'اللاعب'),
                  items: [
                    for (final p in players)
                      DropdownMenuItem(
                        value: p.id,
                        child: Text('${p.name} · ${p.team}${p.position == 'GK' ? ' 🧤' : ''}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _playerId = v),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _link,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(hintText: 'لينك الفيديو'),
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'بيترشّح…' : 'رشّح')),
            ],
          );
        },
      ),
    );
  }
}
