import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// لينكات جوجل مابس: التحقق + استخراج الإحداثيات (حتى من اللينك المختصر maps.app.goo.gl).
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
  static LatLng? parse(String url) {
    final s = Uri.decodeFull(url);
    for (final re in _patterns) {
      final m = re.firstMatch(s);
      if (m == null) continue;
      final lat = double.tryParse(m.group(1)!);
      final lng = double.tryParse(m.group(2)!);
      if (lat == null || lng == null) continue;
      if (lat.abs() > 90 || lng.abs() > 180 || (lat == 0 && lng == 0)) continue;
      return LatLng(lat, lng);
    }
    return null;
  }

  /// إحداثيات من أي لينك جوجل مابس — لو مختصر بيمشي ورا التحويلات لحد اللينك الكامل.
  static Future<LatLng?> resolve(String url) async {
    final direct = parse(url);
    if (direct != null) return direct;
    final client = http.Client();
    try {
      var current = Uri.parse(url);
      for (var i = 0; i < 6; i++) {
        final req = http.Request('GET', current)..followRedirects = false;
        final res = await client.send(req).timeout(const Duration(seconds: 10));
        final location = res.headers['location'];
        await res.stream.drain<void>();
        if (location == null) return null;
        current = current.resolve(location);
        final p = parse(current.toString());
        if (p != null) return p;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
