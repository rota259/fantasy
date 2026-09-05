import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../points/points_engine.dart';
import '../cubit/manager_match_cubit.dart';
import '../data/lineup_repository.dart';

/// أنواع الأحداث اللي المدير يقدر يسجّلها.
const _eventTypes = [
  ('goal', 'جول'), ('assist', 'أسيست'), ('cleanSheet', 'شباك نظيفة'),
  ('save', 'تصدّي'), ('bonus', 'بونص'), ('yellowCard', 'أصفر'), ('redCard', 'أحمر'),
];

/// المراكز (كود، عربي).
const _positions = [('GK', 'حارس'), ('DEF', 'دفاع'), ('MID', 'وسط'), ('FWD', 'مهاجم')];

class ManagerMatchScreen extends StatelessWidget {
  const ManagerMatchScreen({
    super.key,
    required this.match,
    required this.playersRepo,
    required this.eventsRepo,
    required this.lineupRepo,
  });

  final GameMatch match;
  final PlayersRepository playersRepo;
  final EventsRepository eventsRepo;
  final LineupRepository lineupRepo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerMatchCubit(playersRepo, eventsRepo, lineupRepo, match)..load(),
      child: _View(match: match),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.match});
  final GameMatch match;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  String _mode = 'lineup'; // lineup | events
  String? _playerId;
  String _type = 'goal';
  final _minute = TextEditingController();

  @override
  void dispose() {
    _minute.dispose();
    super.dispose();
  }

  void _add(ManagerMatchCubit cubit) {
    if (_playerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر اللاعب الأول')));
      return;
    }
    cubit.addEvent(_playerId!, _type, int.tryParse(_minute.text));
    _minute.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: '${widget.match.teamA} ضد ${widget.match.teamB}',
            subtitle: 'إدارة الماتش · MANAGE',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: BlocBuilder<ManagerMatchCubit, ManagerMatchState>(
              builder: (context, s) {
                if (s.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final cubit = context.read<ManagerMatchCubit>();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _modeToggle(),
                    const SizedBox(height: 16),
                    if (_mode == 'lineup')
                      ..._lineupSection(cubit, s)
                    else
                      ..._eventsSection(cubit, s),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeToggle() {
    Widget tab(String label, String value) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _mode = value),
            child: Container(
              padding: const EdgeInsets.all(11),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _mode == value ? AppColors.accent : null,
                border: Border.all(
                    color: _mode == value ? AppColors.accent : AppColors.black, width: 2),
              ),
              child: Text(label,
                  style: AppText.h(13, color: _mode == value ? AppColors.white : AppColors.ink)),
            ),
          ),
        );
    return Row(children: [tab('التشكيلة', 'lineup'), const SizedBox(width: 8), tab('الأحداث', 'events')]);
  }

  List<Widget> _lineupSection(ManagerMatchCubit cubit, ManagerMatchState s) {
    final a = s.players.where((p) => p.team == widget.match.teamA).toList();
    final b = s.players.where((p) => p.team == widget.match.teamB).toList();
    return [
      Text('نزّل تشكيلة الفريقين', style: AppText.h(15)),
      const SizedBox(height: 4),
      Text('ضيف اللاعيبة وحدّد مين أساسي ومين احتياطي.',
          style: AppText.body(11, color: AppColors.neutral700)),
      const SizedBox(height: 12),
      ..._teamBlock(cubit, s, widget.match.teamA, a),
      const SizedBox(height: 18),
      ..._teamBlock(cubit, s, widget.match.teamB, b),
    ];
  }

  List<Widget> _teamBlock(ManagerMatchCubit cubit, ManagerMatchState s, String team, List<Player> players) {
    return [
      Row(children: [
        Expanded(child: Text(team, style: AppText.h(14, color: AppColors.accent))),
        GestureDetector(
          onTap: () => _addPlayer(cubit, team),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
            child: Text('+ ضيف لاعب', style: AppText.h(11)),
          ),
        ),
      ]),
      if (players.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('لسه مفيش لاعيبة — اضغط "+ ضيف لاعب"',
              style: AppText.body(11, color: AppColors.neutral600)),
        ),
      for (final p in players)
        _lineupRow(p.name, p.positionAr, s.lineup[p.id] ?? 'out',
            (status) => cubit.setLineup(p.id, status)),
    ];
  }

  void _addPlayer(ManagerMatchCubit cubit, String team) {
    final nameCtrl = TextEditingController();
    var pos = 'FWD';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('ضيف لاعب لـ $team', style: AppText.h(15)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                    child: TextField(
                      controller: nameCtrl,
                      style: AppText.h(14),
                      decoration: const InputDecoration(
                        isDense: true, border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        hintText: 'اسم اللاعب',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final p in _positions)
                      GestureDetector(
                        onTap: () => setSheet(() => pos = p.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: pos == p.$1 ? AppColors.accent : null,
                            border: Border.all(color: pos == p.$1 ? AppColors.accent : AppColors.black, width: 2),
                          ),
                          child: Text(p.$2, style: AppText.h(12, color: pos == p.$1 ? AppColors.white : AppColors.ink)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      if (nameCtrl.text.trim().isEmpty) return;
                      cubit.addPlayerToTeam(nameCtrl.text.trim(), team, pos);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      color: AppColors.accent,
                      padding: const EdgeInsets.all(13),
                      alignment: Alignment.center,
                      child: Text('أضِف', style: AppText.h(14, color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lineupRow(String name, String team, String status, ValueChanged<String> onSet) {
    Widget opt(String label, String value) => GestureDetector(
          onTap: () => onSet(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: status == value ? AppColors.accent : null,
              border: Border.all(
                  color: status == value ? AppColors.accent : AppColors.divider, width: 2),
            ),
            child: Text(label,
                style: AppText.h(10, color: status == value ? AppColors.white : AppColors.ink)),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppText.h(13)),
            Text(team, style: AppText.body(9, color: AppColors.neutral700)),
          ]),
        ),
        opt('أساسي', 'starting'),
        const SizedBox(width: 5),
        opt('احتياطي', 'bench'),
        const SizedBox(width: 5),
        opt('بره', 'out'),
      ]),
    );
  }

  List<Widget> _eventsSection(ManagerMatchCubit cubit, ManagerMatchState s) {
    return [
      _playerPicker(s.players.map((p) => (p.id, '${p.name} · ${p.team}')).toList()),
      const SizedBox(height: 12),
      _typeChips(),
      const SizedBox(height: 12),
      _minuteField(),
      const SizedBox(height: 12),
      _addButton(() => _add(cubit)),
      const SizedBox(height: 20),
      Text('الأحداث المسجّلة', style: AppText.h(15)),
      const SizedBox(height: 6),
      if (s.events.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('لسه مفيش أحداث', style: AppText.body(12, color: AppColors.neutral600)),
        ),
      for (final e in s.events)
        _eventRow(cubit.playerName(e.playerId), e.type, e.minute, () => cubit.removeEvent(e.id)),
    ];
  }

  Widget _playerPicker(List<(String, String)> players) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
      child: DropdownButton<String>(
        value: _playerId,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        hint: Text('اختر اللاعب', style: AppText.body(13, color: AppColors.neutral600)),
        items: [
          for (final p in players)
            DropdownMenuItem(value: p.$1, child: Text(p.$2, style: AppText.body(13))),
        ],
        onChanged: (v) => setState(() => _playerId = v),
      ),
    );
  }

  Widget _typeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in _eventTypes)
          GestureDetector(
            onTap: () => setState(() => _type = t.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _type == t.$1 ? AppColors.accent : null,
                border: Border.all(color: _type == t.$1 ? AppColors.accent : AppColors.black, width: 2),
              ),
              child: Text(t.$2, style: AppText.h(12, color: _type == t.$1 ? AppColors.white : AppColors.ink)),
            ),
          ),
      ],
    );
  }

  Widget _minuteField() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
      child: TextField(
        controller: _minute,
        keyboardType: TextInputType.number,
        style: AppText.h(14),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          hintText: 'الدقيقة (اختياري)',
        ),
      ),
    );
  }

  Widget _addButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.accent,
        padding: const EdgeInsets.all(13),
        alignment: Alignment.center,
        child: Text('أضِف الحدث', style: AppText.h(14, color: AppColors.white)),
      ),
    );
  }

  Widget _eventRow(String name, String type, int? minute, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        SizedBox(width: 34, child: Text(minute != null ? "$minute'" : '—', style: AppText.h(12, color: AppColors.accent))),
        Expanded(child: Text(name, style: AppText.h(13))),
        Text(PointsEngine.eventLabel(type), style: AppText.body(11, color: AppColors.neutral700)),
        const SizedBox(width: 10),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.close, size: 18, color: AppColors.danger)),
      ]),
    );
  }
}
