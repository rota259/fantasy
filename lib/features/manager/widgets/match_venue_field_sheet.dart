part of 'match_venue_field.dart';

/// شيت اختيار الملعب: كل الملاعب المتسجّلة على الأبلكيشن (ملاعب منطقتي الأول) + بحث،
/// أو ملعب مش متسجّل: اسم + عنوان بالإيد.
class _VenueSheet extends StatefulWidget {
  const _VenueSheet({required this.zoneId, this.initial});
  final int? zoneId;
  final MatchPlace? initial;

  @override
  State<_VenueSheet> createState() => _VenueSheetState();
}

class _VenueSheetState extends State<_VenueSheet> {
  late final Future<List<Venue>> _venues;
  final _q = TextEditingController();
  late final _name = TextEditingController(text: widget.initial?.venueId == null ? widget.initial?.name : null);
  late final _address = TextEditingController(text: widget.initial?.venueId == null ? widget.initial?.address : null);

  @override
  void initState() {
    super.initState();
    _venues = context.read<VenuesRepository>().fetchAll();
    _q.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_q, _name, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _manual() {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب اسم الملعب وعنوانه')));
      return;
    }
    Navigator.pop(context, MatchPlace(name: _name.text.trim(), address: _address.text.trim()));
  }

  Widget _tile(Venue v) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 38,
      height: 38,
      child: ClipOval(
        child: v.logoUrl != null
            ? NetImage(v.logoUrl!, fallback: Icon(Icons.stadium_outlined, color: AppColors.accent))
            : Icon(Icons.stadium_outlined, color: AppColors.accent),
      ),
    ),
    title: Text(v.name, style: AppText.h(14)),
    subtitle: Text([if (v.address != null) v.address!, '${v.price}ج/ساعة'].join(' · '), style: AppText.body(11)),
    selected: widget.initial?.venueId == v.id,
    onTap: () => Navigator.pop(context, MatchPlace(name: v.name, address: v.address, venueId: v.id)),
  );

  Widget _group(String title) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 2),
    child: Text(title, style: AppText.h(12, color: AppColors.neutral700)),
  );

  Widget _list(AsyncSnapshot<List<Venue>> snap) {
    if (snap.hasError) return Text('تعذّر تحميل الملاعب — اكتب الاسم والعنوان تحت', style: AppText.body(12));
    final all = snap.data;
    if (all == null) return const LinearProgressIndicator();
    if (all.isEmpty) {
      return Text(
        'لسه مفيش ملاعب متسجّلة على الأبلكيشن — اكتب اسم الملعب وعنوانه تحت',
        style: AppText.body(12, color: AppColors.neutral700),
      );
    }
    final q = _q.text.trim();
    final shown = [
      for (final v in all)
        if (q.isEmpty || v.name.contains(q) || (v.address?.contains(q) ?? false)) v,
    ];
    final mine = [
      for (final v in shown)
        if (widget.zoneId != null && v.zoneId == widget.zoneId) v,
    ];
    final others = [
      for (final v in shown)
        if (!mine.contains(v)) v,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (all.length > 5)
          TextField(
            controller: _q,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'دوّر على ملعب'),
          ),
        if (shown.isEmpty) Padding(padding: const EdgeInsets.all(8), child: Text('مفيش ملعب بالاسم ده')),
        if (mine.isNotEmpty) ...[_group('ملاعب منطقتك'), for (final v in mine) _tile(v)],
        if (others.isNotEmpty) ...[
          _group(mine.isEmpty ? 'الملاعب على الأبلكيشن' : 'ملاعب تانية على الأبلكيشن'),
          for (final v in others) _tile(v),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(18, 4, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('الماتش في أنهي ملعب؟', style: AppText.h(18)),
          FutureBuilder<List<Venue>>(future: _venues, builder: (context, snap) => _list(snap)),
          const SizedBox(height: 14),
          Text('ملعب مش متسجّل على الأبلكيشن', style: AppText.h(13)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            maxLength: 60,
            decoration: const InputDecoration(hintText: 'اسم الملعب'),
          ),
          TextField(
            controller: _address,
            maxLength: 120,
            decoration: const InputDecoration(hintText: 'العنوان (مثلًا: الحي التاني جنب المسجد)'),
          ),
          FilledButton(onPressed: _manual, child: const Text('تمام')),
        ],
      ),
    ),
  );
}
