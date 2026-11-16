import 'dart:async';

import 'package:app_links/app_links.dart' as pkg;

import '../app_links.dart';

/// لينكات بتفتح الأبلكيشن على صفحة (بطولة · ملعب · ماتش · دوري بكود).
///
/// اللينك اللي بيتشيّر على واتساب = صفحة ويب صغيرة (docs/l/index.html) لأن واتساب مبيفتحش غير http(s).
/// الصفحة بتفتح الأبلكيشن بـ khomasi://open?t=..&id=.. — ولو مش متسطّب بتودّي على التحميل.
/// جوه الأبلكيشن اللينك بيتحوّل لنفس صيغة الإشعارات (tournament:ID · venue:ID · match:ID · join:CODE)
/// وبيتفتح بـ NotificationRouter.
abstract final class DeepLinks {
  DeepLinks._();

  static const _kinds = {'tournament', 'venue', 'match', 'join'};
  static StreamSubscription<Uri>? _sub;

  /// اللينك اللي يتبعت: [kind] = tournament · venue · match · join.
  static String url(String kind, String id) => '${AppLinks.openBase}?t=$kind&id=${Uri.encodeQueryComponent(id)}';

  /// khomasi://open?t=venue&id=X أو https://…/l/?t=venue&id=X → «venue:X» (null = مش لينك بتاعنا).
  static String? toRoute(Uri u) {
    final t = u.queryParameters['t'], id = u.queryParameters['id'];
    if (t == null || id == null || id.isEmpty || !_kinds.contains(t)) return null;
    return '$t:$id';
  }

  /// بيسمع للينكات (وأول لينك فتح الأبلكيشن) — مرة واحدة بعد الدخول.
  static void listen(void Function(String route) onRoute) {
    _sub ??= pkg.AppLinks().uriLinkStream.listen((u) {
      final r = toRoute(u);
      if (r != null) onRoute(r);
    }, onError: (_) {});
  }
}
