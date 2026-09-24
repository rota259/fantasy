import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/geo_search.dart';
import '../widgets/osm_layers.dart';

/// (مدير) اختيار مكان الملعب: ابحث بالاسم أو دوس على الخريطة يتحط الدبوس.
/// بيرجّع LatLng بـ Navigator.pop.
class VenueMapPicker extends StatefulWidget {
  const VenueMapPicker({super.key, this.initial});
  final LatLng? initial;

  @override
  State<VenueMapPicker> createState() => _VenueMapPickerState();
}

class _VenueMapPickerState extends State<VenueMapPicker> {
  final _map = MapController();
  final _query = TextEditingController();
  late LatLng? _picked = widget.initial;
  List<Place> _results = const [];
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      final r = await GeoSearch.search(_query.text);
      if (!mounted) return;
      setState(() => _results = r);
      if (r.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ملقتش المكان — دوّر على الخريطة ودوس على مكان الملعب')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البحث مش شغّال دلوقتي')));
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _goTo(Place p) {
    setState(() {
      _picked = p.point;
      _results = const [];
    });
    _map.move(p.point, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const StatusArea(),
        Masthead(title: 'مكان الملعب', subtitle: 'دوس على الخريطة', onBack: () => Navigator.pop(context)),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  style: AppText.h(13),
                  decoration: const InputDecoration(
                    isDense: true, border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'ابحث: المعادي، مدينة نصر، اسم الملعب…',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _searching ? null : _search,
              child: Container(
                width: 44, height: 44, color: AppColors.accent,
                child: _searching
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Icon(Icons.search, color: AppColors.white),
              ),
            ),
          ]),
        ),
        for (final p in _results)
          ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined, color: AppColors.accent),
            title: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.body(12)),
            onTap: () => _goTo(p),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.initial ?? cairo,
              initialZoom: widget.initial == null ? 11 : 16,
              onTap: (_, point) => setState(() => _picked = point),
            ),
            children: [
              osmTiles(),
              if (_picked != null) MarkerLayer(markers: [venuePin(_picked!, selected: true)]),
              osmAttribution(),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: AppColors.black,
          padding: const EdgeInsets.all(12),
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: _picked == null ? null : () => Navigator.pop(context, _picked),
              child: Container(
                color: _picked == null ? AppColors.neutral600 : AppColors.accent,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(_picked == null ? 'دوس على مكان الملعب في الخريطة' : '✓ تأكيد الموقع',
                    style: AppText.h(14, color: AppColors.white)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
