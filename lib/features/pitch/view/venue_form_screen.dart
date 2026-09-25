import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/box_field.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../../core/supabase/db_error.dart';
import '../data/maps_link.dart';
import '../data/models/venue.dart';
import '../data/venues_repository.dart';
import '../widgets/venue_form_fields.dart';
import '../widgets/venue_location_field.dart';
import '../widgets/venue_photos_editor.dart';

/// إضافة/تعديل ملعب: البيانات + الموقع + الصور + المواعيد.
/// أي يوزر يضيف ملعبه ويبقى صاحبه (بيوافق على الحجوزات). المدير بس يقدر يغيّر صاحب الملعب.
class VenueFormScreen extends StatefulWidget {
  const VenueFormScreen({super.key, required this.userId, this.editing, this.isManager = false});
  final String userId;
  final Venue? editing;
  final bool isManager;

  @override
  State<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends State<VenueFormScreen> {
  late final Venue? _v = widget.editing;
  late final _name = TextEditingController(text: _v?.name ?? '');
  late final _phone = TextEditingController(text: _v?.phone ?? '');
  late final _price = TextEditingController(text: _v == null ? '' : '${_v.price}');
  late final _address = TextEditingController(text: _v?.address ?? '');
  late final _feature = TextEditingController(text: _v?.feature ?? '');
  late final _link = TextEditingController(text: _v?.mapsUrl ?? '');
  late int _open = _v?.openHour ?? 16;
  late int _close = _v?.closeHour ?? 24;
  late List<String> _photos = [...?_v?.photos];
  late LatLng? _loc = _v != null && _v.hasLocation ? LatLng(_v.lat!, _v.lng!) : null;
  // ملعب جديد من يوزر عادي → هو صاحبه
  late String? _ownerId = _v?.ownerId ?? (widget.isManager ? null : widget.userId);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _price, _address, _feature, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) return 'اكتب اسم الملعب';
    final price = int.tryParse(_price.text.trim());
    if (price == null || price <= 0) return 'اكتب سعر الساعة بالجنيه';
    if (_phone.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length < 8) return 'اكتب رقم تليفون الملعب';
    final link = _link.text.trim();
    if (link.isNotEmpty) {
      final url = MapsLink.extractUrl(link);
      if (url == null || !MapsLink.isGoogleMaps(url)) return 'لينك الموقع لازم يبقى لينك جوجل مابس';
    } else if (_loc == null) {
      return 'حط لينك جوجل مابس للملعب أو حدّده على الخريطة';
    }
    return null;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final err = _validate();
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    final repo = context.read<VenuesRepository>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    // اللينك هو الأدق: لو موجود نطلّع منه المكان (حتى لو مختصر). لو فشل نفضل على نقطة الخريطة.
    final url = MapsLink.extractUrl(_link.text.trim());
    if (url != null) {
      final p = await MapsLink.resolve(url);
      if (p != null) _loc = p;
      if (!mounted) return;
      if (_loc == null && !await confirmNoPin(context)) {
        setState(() => _saving = false);
        return;
      }
    }
    try {
      await repo.save(
        Venue(
          id: _v?.id ?? '',
          name: _name.text.trim(),
          price: int.parse(_price.text.trim()),
          phone: _phone.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          feature: _feature.text.trim().isEmpty ? null : _feature.text.trim(),
          lat: _loc?.latitude,
          lng: _loc?.longitude,
          mapsUrl: url,
          openHour: _open,
          closeHour: _close,
          photos: _photos,
          ownerId: _ownerId,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'فشل الحفظ — جرّب تاني'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: _v == null ? 'ملعب جديد' : 'تعديل ملعب',
            subtitle: 'VENUE',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FieldLabel('الصور'),
                VenuePhotosEditor(
                  userId: widget.userId,
                  photos: _photos,
                  onChanged: (p) => setState(() => _photos = p),
                ),
                FieldLabel('البيانات'),
                BoxField(controller: _name, hint: 'اسم الملعب'),
                BoxField(controller: _phone, hint: 'تليفون الملعب (للاتصال والواتساب)', keyboard: TextInputType.phone),
                BoxField(controller: _price, hint: 'سعر الساعة (جنيه)', keyboard: TextInputType.number),
                BoxField(controller: _address, hint: 'العنوان بالتفصيل (اختياري)'),
                BoxField(controller: _feature, hint: 'ميزة: إضاءة / مغطّى / … (اختياري)'),
                FieldLabel('الموقع (لينك جوجل مابس — الأدق)'),
                VenueLocationField(link: _link, location: _loc, onLocation: (p) => setState(() => _loc = p)),
                FieldLabel('مواعيد التشغيل (كل ساعة = ميعاد حجز)'),
                HoursPicker(
                  open: _open,
                  close: _close,
                  onChanged: (o, c) => setState(() {
                    _open = o;
                    _close = c;
                  }),
                ),
                if (widget.isManager) ...[
                  FieldLabel('صاحب الملعب (بيوافق على الحجوزات)'),
                  OwnerPicker(ownerId: _ownerId, onChanged: (id) => setState(() => _ownerId = id)),
                ],
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    color: _saving ? AppColors.neutral500 : AppColors.accent,
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.center,
                    child: Text(_saving ? 'بيتحفظ…' : 'احفظ الملعب', style: AppText.h(14, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
