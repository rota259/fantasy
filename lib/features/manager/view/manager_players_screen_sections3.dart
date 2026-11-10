part of 'manager_players_screen.dart';

extension _ViewStateSections3 on _ViewState {
  Widget _buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: widget.organizer ? 'لاعيبتي' : 'إدارة اللاعيبة',
            subtitle: widget.organizer ? 'MY PLAYERS' : 'ADMIN · PLAYERS',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: BlocBuilder<ManagerPlayersCubit, ManagerPlayersState>(
              builder: (context, s) {
                final cubit = context.read<ManagerPlayersCubit>();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!widget.organizer) ...[
                      _field(_name, 'اسم اللاعب'),
                      const SizedBox(height: 10),
                      _field(_team, 'النادي'),
                      const SizedBox(height: 10),
                      _positionChips(),
                      const SizedBox(height: 12),
                      Pressable(
                        onTap: () => _add(cubit),
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                          padding: const EdgeInsets.all(13),
                          alignment: Alignment.center,
                          child: Text('أضِف اللاعب', style: AppText.h(14, color: AppColors.white)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'بتضيف لاعيبة من تشكيلة الماتش. الحذف للاعيبة اللي لسه ملعبوش بس — اللي لعب كلّم الإدارة.',
                          style: AppText.body(11, color: AppColors.neutral700),
                        ),
                      ),
                    SelectionBar(
                      title: 'اللاعيبة (${s.players.length})',
                      selecting: _sel != null,
                      selected: _sel?.length ?? 0,
                      total: s.players.length,
                      onStart: () => _update(() => _sel = {}),
                      onCancel: () => _update(() => _sel = null),
                      onSelectAll: () => _update(() {
                        _sel = _sel!.length == s.players.length ? {} : {for (final p in s.players) p.id};
                      }),
                      actions: [
                        (
                          label: 'احذف المحدّد (${_sel?.length ?? 0})',
                          color: AppColors.danger,
                          onTap: (_sel?.isEmpty ?? true) ? null : () => _bulkDelete(cubit, _sel!.toList(), all: false),
                        ),
                        (
                          label: 'احذف الكل (${s.players.length})',
                          color: AppColors.black,
                          onTap: () => _bulkDelete(cubit, [for (final p in s.players) p.id], all: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (s.isLoading) Padding(padding: EdgeInsets.all(20), child: const SkeletonList()),
                    if (!s.isLoading && s.players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'لسه مضفتش لاعيبة. ضيف أول لاعب من فوق.',
                          style: AppText.body(12, color: AppColors.neutral600),
                        ),
                      ),
                    // كل فريق لوحده وتحته لاعيبته (الحارس الأول)
                    for (final team in _byTeam(s.players).entries) ...[
                      _teamHeader(team.key, team.value),
                      for (final p in team.value)
                        if (_sel != null)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsetsDirectional.only(start: 12),
                            value: _sel!.contains(p.id),
                            onChanged: (on) => _update(() => on == true ? _sel!.add(p.id) : _sel!.remove(p.id)),
                            title: Text(p.name, style: AppText.h(13)),
                            subtitle: Text(p.positionAr, style: AppText.body(10)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 12),
                            child: _playerRow(
                              '${p.name}${p.position == 'GK' ? ' 🧤' : ''}',
                              p.positionAr,
                              onEdit: widget.organizer ? null : () => showPlayerEditSheet(context, cubit, p),
                              onDelete: () => _confirmDelete(cubit, p.id, p.name),
                            ),
                          ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
