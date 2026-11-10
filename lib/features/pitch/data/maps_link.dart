/// لينكات جوجل مابس: التحقق + الإحداثيات لو مكتوبة في اللينك نفسه (مفيش خرايط جوه الأبلكيشن —
/// زرار «الموقع» بيفتح اللينك في تطبيق الخرايط).
abstract final class MapsLink {
  MapsLink._();

  static final _urlInText = RegExp(r'https?://\S+');
  static const _n = r'(-?\d{1,3}(?:\.\d+)?)';

  // بالترتيب من الأدق للأقل دقة:
  static final _patterns = [
    RegExp('!3d$_n!4d$_n'), // مكان محدّد (place)
    RegExp('[?&](?:q|query|ll|destination|daddr|center)=$_n,\\s*$_n'),
    RegExp('/(?:place|search|dir)/$_n,\\s*$_n'),
    RegExp('@$_n,$_n'), // وسط الشاشة
  ];

  /// بيطلّع اللينك من نص المشاركة (ممكن يبقى فيه اسم المكان قبل اللينك).
  static String? extractUrl(String text) => _urlInText.firstMatch(text.trim())?.group(0);

  /// هل ده لينك جوجل مابس؟
  static bool isGoogleMaps(String url) {
    final u = Uri.tryParse(url);
    if (u == null || !u.hasScheme) return false;
    final h = u.host.toLowerCase();
    return h == 'maps.app.goo.gl' ||
        h == 'goo.gl' && u.path.startsWith('/maps') ||
        h.startsWith('maps.google.') ||
        (h.contains('google.') && u.path.startsWith('/maps'));
  }

  /// إحداثيات من اللينك مباشرة (من غير نت). null لو مفيش.
  static ({double lat, double lng})? parse(String url) {
    final s = Uri.decodeFull(url);
    for (final re in _patterns) {
      final m = re.firstMatch(s);
      if (m == null) continue;
      final lat = double.tryParse(m.group(1)!);
      final lng = double.tryParse(m.group(2)!);
      if (lat == null || lng == null) continue;
      if (lat.abs() > 90 || lng.abs() > 180 || (lat == 0 && lng == 0)) continue;
      return (lat: lat, lng: lng);
    }
    return null;
  }
}
