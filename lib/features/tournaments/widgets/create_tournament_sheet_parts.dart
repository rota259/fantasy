part of 'create_tournament_sheet.dart';

extension _CreateSheetParts on _CreateSheetState {
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (t == null) return;
    _set(() => _start = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  /// ملاعبي الموثّقة (والأدمن: كل الملاعب الموثّقة).
  Future<List<Venue>> _loadVenues() async {
    final repo = context.read<VenuesRepository>();
    final u = context.read<AuthCubit>().state.user;
    final list = (u?.isManager ?? false) ? await repo.fetchAll() : await repo.fetchOwned(u?.id ?? '');
    final ok = list.where((v) => v.verified || !kVenueVerify).toList();
    if (ok.length == 1 && mounted) _set(() => _venue = ok.first.id);
    return ok;
  }

  Widget _venuePicker() => FutureBuilder<List<Venue>>(
    future: _venues,
    builder: (context, snap) {
      final list = snap.data;
      if (list == null) return const LinearProgressIndicator();
      if (list.isEmpty) {
        return Text(
          kVenueVerify
              ? 'لازم يبقى عندك ملعب موثّق — ضيف ملعبك من «ملاعبي» وكلّم الإدارة توثّقه'
              : 'ضيف ملعبك الأول من «حسابي ← ملاعبي»',
          style: AppText.body(12, color: AppColors.danger),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الملعب', style: AppText.h(13)),
          Wrap(
            spacing: 6,
            children: [
              for (final v in list)
                ChoiceChip(label: Text(v.name), selected: _venue == v.id, onSelected: (_) => _set(() => _venue = v.id)),
            ],
          ),
        ],
      );
    },
  );

  Widget _stepper(String label, int v, int min, int max, ValueChanged<int> onChanged) => Row(
    children: [
      Expanded(child: Text(label, style: AppText.h(13))),
      IconButton(onPressed: v > min ? () => onChanged(v - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
      Text('$v', style: AppText.h(16)),
      IconButton(onPressed: v < max ? () => onChanged(v + 1) : null, icon: const Icon(Icons.add_circle_outline)),
    ],
  );
}
