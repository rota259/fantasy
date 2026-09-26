import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/zone.dart';
import '../data/zones_repository.dart';

/// اختيار المنطقة: المحافظة الأول، وبعدين المنطقة (مع بحث).
Future<Zone?> showZonePicker(BuildContext context) => showModalBottomSheet<Zone>(
  context: context,
  backgroundColor: AppColors.bg,
  isScrollControlled: true,
  builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: _ZonePicker(repo: context.read<ZonesRepository>())),
);

class _ZonePicker extends StatefulWidget {
  const _ZonePicker({required this.repo});
  final ZonesRepository repo;

  @override
  State<_ZonePicker> createState() => _ZonePickerState();
}

class _ZonePickerState extends State<_ZonePicker> {
  late final Future<List<Zone>> _zones = widget.repo.fetchAll();
  String? _gov;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<Zone>>(
        future: _zones,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('مقدرتش أحمّل المناطق — جرّب تاني', style: AppText.body(13)));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          final all = snap.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              if (_gov != null) _search(),
              Expanded(child: _gov == null ? _governorates(all) : _areas(all)),
            ],
          );
        },
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Row(
      children: [
        if (_gov != null)
          GestureDetector(
            onTap: () => setState(() {
              _gov = null;
              _query = '';
            }),
            child: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.arrow_forward)),
          ),
        Expanded(child: Text(_gov == null ? 'اختار المحافظة' : 'منطقتك في $_gov', style: AppText.h(16))),
      ],
    ),
  );

  Widget _search() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
      onChanged: (v) => setState(() => _query = v.trim()),
      style: AppText.body(14),
      decoration: const InputDecoration(
        hintText: 'دوّر على منطقتك…',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget _governorates(List<Zone> all) {
    final govs = <String>[];
    for (final z in all) {
      if (!govs.contains(z.governorate)) govs.add(z.governorate);
    }
    return ListView(children: [for (final g in govs) _row(g, () => setState(() => _gov = g))]);
  }

  Widget _areas(List<Zone> all) {
    final list = all.where((z) => z.governorate == _gov && (_query.isEmpty || z.name.contains(_query))).toList();
    if (list.isEmpty) {
      return Center(
        child: Text('مفيش منطقة بالاسم ده', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    return ListView(children: [for (final z in list) _row(z.name, () => Navigator.pop(context, z))]);
  }

  Widget _row(String text, VoidCallback onTap) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppText.h(14))),
          Text('›', style: AppText.body(16, color: AppColors.neutral600)),
        ],
      ),
    ),
  );
}
