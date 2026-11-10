/// تنضيف السجلات قبل ما تتكتب أو تتبعت: مفيش أسرار ولا بيانات شخصية تطلع في log.
///   • أي حقل اسمه فيه password / token / secret / apikey / authorization / cookie / otp / code / card → بيتشال
///   • الإيميلات والأرقام جوه أي نص بتتغطّى:  a***@gmail.com  ·  010*****78
///   • القيم بسيطة بس (نص · رقم · bool) — أي حاجة مركّبة بتتحوّل لنص قصير
abstract final class LogRedact {
  static final _secretKey = RegExp(
    r'(pass|token|secret|api_?key|authorization|cookie|otp|^code$|card|cvv|national)',
    caseSensitive: false,
  );
  static final _email = RegExp(r'([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+)');
  static final _phone = RegExp(r'(\+?\d{3})\d{4,9}(\d{2})');
  static final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}');

  /// نص آمن: التوكنات بتتشال، والإيميلات والأرقام بتتغطّى، والطول بيتحدّ.
  static String text(Object? value, {int max = 500}) {
    var s = '$value'
        .replaceAll(_jwt, '[token]')
        .replaceAllMapped(_email, (m) => '${m[1]}***@${m[2]}')
        .replaceAllMapped(_phone, (m) => '${m[1]}*****${m[2]}');
    if (s.length > max) s = '${s.substring(0, max)}…';
    return s;
  }

  /// حقول آمنة: المفاتيح الحسّاسة بتتشال والقيم بتتنضّف.
  static Map<String, Object?> fields(Map<String, Object?>? raw) {
    final out = <String, Object?>{};
    if (raw == null) return out;
    raw.forEach((k, v) {
      if (_secretKey.hasMatch(k) || out.length >= 20) return;
      out[k] = (v == null || v is num || v is bool) ? v : text(v, max: 300);
    });
    return out;
  }

  /// نوع الخطأ من غير تفاصيله (اسم الكلاس بس).
  static String typeOf(Object error) => error.runtimeType.toString();
}
