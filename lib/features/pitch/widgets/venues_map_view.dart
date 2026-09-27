import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/models/venue.dart';
import 'osm_layers.dart';
import '../../../core/widgets/motion.dart';

/// الملاعب كدبابيس على الخريطة. الضغط على دبوس بيطلّع كارت صغير يفتح الملعب.
class VenuesMapView extends StatefulWidget {
  const VenuesMapView({super.key, required this.venues, required this.onOpen});

  final List<Venue> venues;
  final ValueChanged<Venue> onOpen;

  @override
  State<VenuesMapView> createState() => _VenuesMapViewState();
}

class _VenuesMapViewState extends State<VenuesMapView> {
  Venue? _selected;

  @override
  Widget build(BuildContext context) {
    final located = widget.venues.where((v) => v.hasLocation).toList();
    final center = located.isEmpty ? cairo : LatLng(located.first.lat!, located.first.lng!);
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: located.isEmpty ? 10 : 12,
            onTap: (_, __) => setState(() => _selected = null),
          ),
          children: [
            osmTiles(),
            MarkerLayer(
              markers: [
                for (final v in located)
                  venuePin(
                    LatLng(v.lat!, v.lng!),
                    selected: v.id == _selected?.id,
                    onTap: () => setState(() => _selected = v),
                  ),
              ],
            ),
            osmAttribution(),
          ],
        ),
        if (located.isEmpty)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
              padding: const EdgeInsets.all(10),
              child: Text(
                'لسه مفيش ملاعب متحدّد مكانها على الخريطة',
                textAlign: TextAlign.center,
                style: AppText.h(12, color: AppColors.white),
              ),
            ),
          ),
        if (_selected != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 30,
            child: Pressable(
              onTap: () => widget.onOpen(_selected!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  color: AppColors.bg,
                  border: Border.all(color: AppColors.line, width: 1.2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!.name, style: AppText.h(15)),
                          Text('${_selected!.price}ج/ساعة', style: AppText.body(11, color: AppColors.neutral700)),
                        ],
                      ),
                    ),
                    Text('افتح ›', style: AppText.h(13, color: AppColors.accent)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
