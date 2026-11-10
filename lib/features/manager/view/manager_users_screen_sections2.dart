part of 'manager_users_screen.dart';

extension _ManagerUsersScreenStateSections2 on _ManagerUsersScreenState {
  Widget _btn(String label, VoidCallback onTap) => Pressable(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Text(label, style: AppText.h(11)),
    ),
  );

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'المستخدمين', subtitle: 'ADMIN · USERS', onBack: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => _update(() {
                _q = v.trim();
                _future = _load();
              }),
              decoration: const InputDecoration(
                hintText: 'دوّر بالاسم أو الإيميل أو الموبايل ودوس بحث',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<(List<AppUser>, Map<int, Zone>, AdminCounts)>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final (all, zones, counts) = snap.data!;
                final users = [
                  for (final u in all)
                    if (!u.isManager) u,
                ]; // الأدمنز مبيتحدّدوش
                final picked = [
                  for (final u in users)
                    if (_sel?.contains(u.id) ?? false) u,
                ];
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        '${counts.users} يوزر · ${counts.admins} أدمن · ${counts.managers} مدير منطقة'
                        '${_q.isEmpty ? ' · الأعلى نقط' : ' · نتايج «$_q»'}',
                        style: AppText.h(14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [_filter('الكل', null), _filter('يوزرز', 'user'), _filter('مديرين', 'organizer')],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: SelectionBar(
                        title: 'القايمة (${users.length})',
                        selecting: _sel != null,
                        selected: picked.length,
                        total: users.length,
                        onStart: () => _update(() => _sel = {}),
                        onCancel: () => _update(() => _sel = null),
                        onSelectAll: () => _update(() {
                          _sel = picked.length == users.length ? {} : {for (final u in users) u.id};
                        }),
                        actions: [
                          (
                            label: 'رجّع المديرين يوزرز (${picked.where((u) => u.isOrganizer).length})',
                            color: AppColors.info,
                            onTap: picked.any((u) => u.isOrganizer) ? () => _bulk(picked, delete: false) : null,
                          ),
                          (
                            label: 'امسح المحدّد (${picked.length})',
                            color: AppColors.danger,
                            onTap: picked.isEmpty ? null : () => _bulk(picked, delete: true),
                          ),
                          (
                            label: 'امسح الكل (${users.length})',
                            color: AppColors.black,
                            onTap: users.isEmpty ? null : () => _bulk(users, delete: true, all: true),
                          ),
                        ],
                      ),
                    ),
                    for (final u in all)
                      if (_sel != null && !u.isManager)
                        CheckboxListTile(
                          dense: true,
                          value: _sel!.contains(u.id),
                          onChanged: (on) => _update(() => on == true ? _sel!.add(u.id) : _sel!.remove(u.id)),
                          title: Text('${u.name}${u.isOrganizer ? ' · مدير' : ''}', style: AppText.h(13)),
                          subtitle: Text(zones[u.zoneId]?.label ?? 'من غير منطقة', style: AppText.body(10)),
                        )
                      else if (_sel == null)
                        _row(u, zones[u.zoneId]),
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
