import 'package:url_launcher/url_launcher.dart';

/// فتح تطبيقات تانية (خرايط / اتصال / واتساب). بيرجّع false لو مفتحش.
abstract final class Launchers {
  Launchers._();

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// يفتح لينك (زي لينك جوجل مابس) في التطبيق المناسب.
  static Future<bool> url(String link) {
    final u = Uri.tryParse(link.trim());
    return u == null ? Future.value(false) : _open(u);
  }

  /// يفتح المكان في جوجل ماب (أو المتصفح لو التطبيق مش موجود).
  static Future<bool> maps(double lat, double lng) => _open(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      );

  static Future<bool> call(String phone) => _open(Uri(scheme: 'tel', path: _digits(phone)));

  /// واتساب مع رسالة جاهزة.
  static Future<bool> whatsapp(String phone, String message) => _open(
        Uri.https('wa.me', '/${_international(phone)}', {'text': message}),
      );

  static String _digits(String p) => p.replaceAll(RegExp(r'[^0-9+]'), '');

  /// رقم مصري للصيغة الدولية: 01012345678 → 201012345678
  static String _international(String p) {
    var d = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0')) d = '20${d.substring(1)}';
    return d;
  }
}
