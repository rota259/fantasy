part of 'manager_players_screen.dart';

extension _ViewStateSections1 on _ViewState {
  void _add(ManagerPlayersCubit cubit) {
    if (_name.text.trim().isEmpty || _team.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الاسم والنادي')));
      return;
    }
    cubit.add(name: _name.text.trim(), team: _team.text.trim(), position: _pos);
    _name.clear();
    _team.clear();
  }

  /// اللاعيبة متقسّمين بالفريق (الفرق بالأبجدية، والحارس أول واحد في فريقه).
  Map<String, List<Player>> _byTeam(List<Player> players) {
    final map = <String, List<Player>>{};
    for (final p in players) {
      map.putIfAbsent(p.team.trim().isEmpty ? 'من غير فريق' : p.team, () => []).add(p);
    }
    for (final l in map.values) {
      l.sort((a, b) {
        final g = (a.position == 'GK' ? 0 : 1).compareTo(b.position == 'GK' ? 0 : 1);
        return g != 0 ? g : a.name.compareTo(b.name);
      });
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  /// عنوان الفريق: اسمه + عدد لاعيبته — ووقت التحديد بيحدّد/يلغي الفريق كله.
  Widget _teamHeader(String team, List<Player> players) {
    final sel = _sel;
    final all = sel != null && players.every((p) => sel.contains(p.id));
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(team, style: AppText.h(14, color: AppColors.accent700)),
          ),
          Text('${players.length} لاعب', style: AppText.body(11, color: AppColors.accent700)),
          if (sel != null)
            Checkbox(
              value: all,
              visualDensity: VisualDensity.compact,
              onChanged: (on) => _update(() {
                for (final p in players) {
                  on == true ? sel.add(p.id) : sel.remove(p.id);
                }
              }),
            ),
        ],
      ),
    );
  }

  /// حذف المحدّدين أو الكل (الكل لازم يكتب "احذف").
  Future<void> _bulkDelete(ManagerPlayersCubit cubit, List<String> ids, {required bool all}) async {
    final ok = await confirmBulk(
      context,
      all ? 'حذف كل اللاعيبة' : 'حذف ${ids.length} لاعب',
      all
          ? 'هتحذف ${ids.length} لاعب، ومعاهم أحداثهم ونقطهم في تشكيلات الناس. مفيش رجوع.'
          : 'متأكد؟ أحداثهم ونقطهم في تشكيلات الناس هتتمسح معاهم.',
      typeToConfirm: all ? 'احذف' : null,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final r = await cubit.removeMany(ids);
    if (!mounted) return;
    _update(() => _sel = null);
    final skipped = r.skipped > 0 ? ' · ${r.skipped} مااتحذفوش (لعبوا واتسجّل لهم أحداث)' : '';
    messenger.showSnackBar(SnackBar(content: Text(r.error ?? 'اتحذف ${r.deleted} ✓$skipped')));
  }

  Future<void> _confirmDelete(ManagerPlayersCubit cubit, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف اللاعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «$name»؟', style: AppText.body(13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppText.h(13, color: AppColors.neutral700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await cubit.remove(id);
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'اتحذف «$name» ✓'), duration: const Duration(milliseconds: 2200)),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: AppText.h(14),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          hintText: hint,
        ),
      ),
    );
  }
}
