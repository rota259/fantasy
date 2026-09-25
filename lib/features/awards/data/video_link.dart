/// لينكات الفيديو (يوتيوب/تيك توك/إنستجرام/فيسبوك/درايف): التحقّق + صورة مصغّرة ليوتيوب.
abstract final class VideoLink {
  VideoLink._();

  static const _hosts = [
    'youtube.com',
    'youtu.be',
    'tiktok.com',
    'instagram.com',
    'facebook.com',
    'fb.watch',
    'drive.google.com',
  ];

  /// لينك فيديو معروف؟
  static bool isValid(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null || !(u.scheme == 'https' || u.scheme == 'http') || u.host.isEmpty) return false;
    final host = u.host.toLowerCase();
    return _hosts.any((h) => host == h || host.endsWith('.$h'));
  }

  /// id فيديو يوتيوب (watch?v= · youtu.be/ · shorts/ · embed/).
  static String? youtubeId(String url) {
    final u = Uri.tryParse(url.trim());
    if (u == null) return null;
    final host = u.host.toLowerCase();
    if (host.endsWith('youtu.be')) return _clean(u.pathSegments.firstOrNull);
    if (!host.endsWith('youtube.com')) return null;
    final v = u.queryParameters['v'];
    if (v != null) return _clean(v);
    final seg = u.pathSegments;
    if (seg.length >= 2 && (seg[0] == 'shorts' || seg[0] == 'embed' || seg[0] == 'live')) return _clean(seg[1]);
    return null;
  }

  static String? _clean(String? id) => (id != null && RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(id)) ? id : null;

  /// صورة مصغّرة (يوتيوب بس — الباقي بيظهر بأيقونة تشغيل).
  static String? thumbnail(String url) {
    final id = youtubeId(url);
    return id == null ? null : 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }
}
