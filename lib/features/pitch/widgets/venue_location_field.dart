import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/maps_link.dart';
import '../view/venue_map_picker.dart';

/// (مدير) موقع الملعب: لينك جوجل مابس (الأدق) — أو تحديده على الخريطة.
class VenueLocationField extends StatefulWidget {
  const VenueLocationField({super.key, required this.link, required this.location, required this.onLocation});

  final TextEditingController link;
  final LatLng? location;
  final ValueChanged<LatLng?> onLocation;

  @override
  State<VenueLocationField> createState() => _VenueLocationFieldState();
}

class _VenueLocationFieldState extends State<VenueLocationField> {
  bool _checking = false;
  String? _msg;
  bool _ok = false;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    widget.link.text = text;
    await _check();
  }

  Future<void> _check() async {
    final url = MapsLink.extractUrl(widget.link.text);
    if (url == null || !MapsLink.isGoogleMaps(url)) {
      setState(() {
        _ok = false;
        _msg = 'ده مش لينك جوجل مابس — من جوجل مابس دوس "مشاركة" وانسخ اللينك';
      });
      return;
    }
    widget.link.text = url;
    setState(() => _checking = true);
    final p = await MapsLink.resolve(url);
    if (!mounted) return;
    if (p != null) widget.onLocation(p);
    setState(() {
      _checking = false;
      _ok = p != null;
      _msg = p != null
          ? 'اتحدد المكان من اللينك ✓'
          : 'اللينك هيتحفظ ويفتح صح، بس مقدرتش أطلّع المكان منه — حدّده على الخريطة كمان عشان يظهر كدبوس';
    });
  }

  Future<void> _pickOnMap() async {
    final p = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => VenueMapPicker(initial: widget.location)),
    );
    if (p != null) widget.onLocation(p);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.link,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _check(),
                  onChanged: (_) => setState(() => _msg = null),
                  style: AppText.body(12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintText: 'لينك جوجل مابس (maps.app.goo.gl/…)',
                  ),
                ),
              ),
              IconButton(tooltip: 'لصق', onPressed: _checking ? null : _paste, icon: const Icon(Icons.content_paste)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _checking
                    ? 'بيتحقق من اللينك…'
                    : (_msg ?? 'من جوجل مابس: افتح الملعب ← مشاركة ← نسخ اللينك، والصقه هنا'),
                style: AppText.body(
                  11,
                  color: _msg == null ? AppColors.neutral600 : (_ok ? AppColors.accent : AppColors.danger),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _checking ? null : _check,
              child: Container(
                color: AppColors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('تحقق', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickOnMap,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              border: Border.all(color: widget.location == null ? AppColors.divider : AppColors.accent, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  widget.location == null ? Icons.map_outlined : Icons.check_circle,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.location == null ? 'أو حدّد مكانه على الخريطة' : 'المكان متحدد على الخريطة ✓ — دوس للتعديل',
                    style: AppText.h(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// اللينك اتحفظ بس مقدرناش نطلّع منه مكان → الملعب مش هيظهر كدبوس في تاب الخريطة.
Future<bool> confirmNoPin(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(),
      title: Text('مقدرتش أحدد المكان من اللينك', style: AppText.h(15)),
      content: Text(
        'زرار "الموقع" هيفتح اللينك عادي، بس الملعب مش هيظهر في تاب الخريطة. '
        'تقدر تحدّده على الخريطة كمان من "أو حدّد مكانه على الخريطة".',
        style: AppText.body(13),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('أحدّده الأول')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('احفظ كده')),
      ],
    ),
  );
  return ok == true;
}
