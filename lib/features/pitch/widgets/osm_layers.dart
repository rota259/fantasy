import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// وسط القاهرة (نقطة البداية لما مفيش موقع).
const cairo = LatLng(30.0444, 31.2357);

/// طبقة خريطة OpenStreetMap (مجانية — لازم User-Agent باسم التطبيق حسب سياستهم).
TileLayer osmTiles() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.fantasy_5omasi',
);

/// حقوق OpenStreetMap (مطلوبة قانونيًا تبان على الخريطة).
Widget osmAttribution() => const RichAttributionWidget(
  showFlutterMapAttribution: false,
  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
);

/// دبوس ملعب على الخريطة.
Marker venuePin(LatLng point, {bool selected = false, VoidCallback? onTap}) => Marker(
  point: point,
  width: 40,
  height: 40,
  alignment: Alignment.topCenter,
  child: GestureDetector(
    onTap: onTap,
    child: Icon(Icons.location_on, size: 40, color: selected ? AppColors.danger : AppColors.accent),
  ),
);
