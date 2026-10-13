import 'package:audioplayers/audioplayers.dart';

/// نغمات الأبلكيشن (الملفات في assets/sounds — ونفسها في res/raw لقنوات إشعارات أندرويد):
///   goal كل هدف · match بداية ونهاية الماتش · lineup التشكيلة نزلت · round الجولة بدأت
///   deadline قبل الديدلاين · general أي إشعار تاني · appStart فتح الأبلكيشن · totwReveal كل لاعب في كشف تشكيلة الجولة
/// بتتشغّل كصوت «إشعار»: لو الموبايل صامت أو هزاز مبتطلعش.
abstract final class AppSounds {
  static const appStart = 'app_start.m4a';
  static const totwReveal = 'totw_reveal.wav';

  /// ملف نغمة الإشعار — [sound] من السيرفر (عمود sound)، ولو مش موجود بنستنتجه من النوع.
  static String fileFor(String? sound, [String kind = '']) =>
      switch (sound ?? (kind == 'lineup' ? 'lineup' : 'general')) {
        'goal' => 'goal.mp3',
        'match' => 'match.wav',
        'lineup' => 'lineup.wav',
        'round' => 'round_start.wav',
        'deadline' => 'deadline.wav',
        _ => 'general.wav',
      };

  /// صوت إشعار: بيمشي مع وضع الموبايل (صامت = مفيش صوت) ومبيقطعش أي حاجة شغّالة.
  static final AudioContext _context = AudioContext(
    android: const AudioContextAndroid(
      usageType: AndroidUsageType.notification,
      contentType: AndroidContentType.sonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static final Map<String, AudioPlayer> _players = {};

  /// بتشغّل ملف من assets/sounds. بتفشل بهدوء (ملف ناقص · منصّة من غير صوت).
  /// [channel]: كل قناة ليها مشغّل (نغمة جديدة على نفس القناة بتقطع القديمة).
  static Future<void> play(String file, {String channel = 'main'}) async {
    try {
      final p = _players[channel] ??= AudioPlayer();
      await p.setAudioContext(_context);
      await p.stop();
      await p.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }
}

/// بتشغّل نغمة كل إشعار جديد والأبلكيشن مفتوح.
class SoundService {
  /// [sound] النغمة اللي السيرفر حددها للإشعار · [kind] نوعه (للإشعارات القديمة اللي من غير نغمة).
  Future<void> play(String kind, [String? sound]) => AppSounds.play(AppSounds.fileFor(sound, kind));

  void dispose() {}
}
