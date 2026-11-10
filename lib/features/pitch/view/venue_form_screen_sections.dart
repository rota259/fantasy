part of 'venue_form_screen.dart';

extension _VenueFormScreenStateSections1 on _VenueFormScreenState {
  String? _validate() {
    if (_name.text.trim().isEmpty) return 'اكتب اسم الملعب';
    final price = int.tryParse(_price.text.trim());
    if (price == null || price <= 0) return 'اكتب سعر الساعة بالجنيه';
    if (_phone.text.trim().replaceAll(RegExp(r'[^0-9]'), '').length < 8) return 'اكتب رقم تليفون الملعب';
    final link = _link.text.trim();
    if (link.isNotEmpty) {
      final url = MapsLink.extractUrl(link);
      if (url == null || !MapsLink.isGoogleMaps(url)) return 'لينك الموقع لازم يبقى لينك جوجل مابس';
    } else if (!(_v?.hasLocation ?? false)) {
      return 'حط لينك جوجل مابس للملعب';
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
    _update(() => _saving = true);
    // الإحداثيات لو مكتوبة في اللينك نفسه (احتياطي لو اللينك اتشال) — من غير أي طلب نت
    final url = MapsLink.extractUrl(_link.text.trim());
    final p = url == null ? null : MapsLink.parse(url);
    final same = url == null || url == _v?.mapsUrl;
    try {
      await repo.save(
        Venue(
          id: _v?.id ?? '',
          name: _name.text.trim(),
          price: int.parse(_price.text.trim()),
          phone: _phone.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          feature: _feature.text.trim().isEmpty ? null : _feature.text.trim(),
          lat: p?.lat ?? (same ? _v?.lat : null),
          lng: p?.lng ?? (same ? _v?.lng : null),
          mapsUrl: url,
          openHour: _open,
          closeHour: _close,
          photos: _photos,
          ownerId: _ownerId,
        ),
      );
      navigator.pop(true);
    } catch (e) {
      if (mounted) _update(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'فشل الحفظ — جرّب تاني'))));
    }
  }
}
