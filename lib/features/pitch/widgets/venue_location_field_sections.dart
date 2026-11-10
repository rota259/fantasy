part of 'venue_location_field.dart';

extension _VenueLocationFieldStateSections1 on _VenueLocationFieldState {
  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    widget.link.text = text;
    _check();
  }

  void _check() {
    final url = MapsLink.extractUrl(widget.link.text);
    final ok = url != null && MapsLink.isGoogleMaps(url);
    if (ok) widget.link.text = url;
    _update(() {
      _ok = ok;
      _msg = ok
          ? 'لينك جوجل مابس ✓ — زرار «الموقع» هيفتحه'
          : 'ده مش لينك جوجل مابس — من جوجل مابس دوس "مشاركة" وانسخ اللينك';
    });
  }
}
