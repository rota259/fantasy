import 'package:audioplayers/audioplayers.dart';

/// بتشغّل صوت مميّز لكل نوع إشعار والأبلكيشن مفتوح.
/// الأصوات في assets/sounds (متولّدة بـ tool/make_sounds.py — ونفسها في res/raw لقنوات أندرويد):
///   goal جول وأحداث · whistle ماتش · lineup تشكيلة · win شارة/تحدّي/تصويت · soft الباقي
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  /// نفس التقسيمة في فانكشن push (channel_id) عشان الصوت يبقى واحد والأبلكيشن مقفول.
  static String _fileFor(String kind) => switch (kind) {
    'event' => 'sounds/goal.wav',
    'match' => 'sounds/whistle.wav',
    'lineup' => 'sounds/lineup.wav',
    'badge' || 'challenge' || 'vote' => 'sounds/win.wav',
    _ => 'sounds/soft.wav',
  };

  /// بتشغّل صوت النوع. بتفشل بهدوء لو الملف مش موجود.
  Future<void> play(String kind) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(_fileFor(kind)));
    } catch (_) {}
  }

  void dispose() => _player.dispose();
}
