part of 'match_events_section.dart';

extension _MatchEventsSectionStateSections1 on _MatchEventsSectionState {
  Future<void> _record(Player p) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = widget.cubit;
    String? other;
    var target = p;
    if (_type == 'sub') {
      final bench = [
        for (final id in cubit.benchLeft)
          if (cubit.player(id) case final q? when q.team == p.team) q,
      ];
      final incoming = await showSubSheet(context, p, bench);
      if (incoming == null) return;
      other = p.id; // اللي طلع
      target = incoming; // اللي نزل
    }
    final err = await cubit.addEvent(target.id, _type, int.tryParse(_minute.text), otherPlayerId: other);
    final label = _type == 'sub' ? '${target.name} مكان ${p.name}' : p.name;
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? '${PointsEngine.eventIcon(_type)} ${PointsEngine.eventLabel(_type)} — $label ✓'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
        duration: Duration(milliseconds: err == null ? 1400 : 4000),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final on = _type == value;
    return Pressable(
      onTap: () => _update(() => _type = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent : AppColors.card,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
      ),
    );
  }

  Widget _eventRow(MatchEvent e) {
    final cubit = widget.cubit;
    final who = e.type == 'sub'
        ? '${cubit.playerName(e.playerId)} ⬆ · ${cubit.playerName(e.otherPlayerId ?? '')} ⬇'
        : cubit.playerName(e.playerId);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: AppDecor.softDivider,
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(e.minute != null ? "${e.minute}'" : '—', style: AppText.h(12, color: AppColors.accent)),
          ),
          Text(PointsEngine.eventIcon(e.type)),
          const SizedBox(width: 6),
          Expanded(child: Text(who, style: AppText.h(13))),
          Text(PointsEngine.eventLabel(e.type), style: AppText.body(11, color: AppColors.neutral700)),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => cubit.removeEvent(e.id),
            child: Icon(Icons.close, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
