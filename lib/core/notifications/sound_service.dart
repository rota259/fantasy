import 'package:audioplayers/audioplayers.dart';

/// بتشغّل صوت مميّز لكل نوع إشعار.
/// الملفات المتوقّعة في assets/sounds/ : lineup.mp3 · match.mp3 · event.mp3 · status.mp3
/// (الأنواع الجديدة بتستخدم أقرب صوت ليها)
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  static String _fileFor(String kind) => switch (kind) {
    'lineup' => 'sounds/lineup.mp3',
    'match' || 'vote' || 'challenge' => 'sounds/match.mp3',
    'status' || 'badge' || 'booking' => 'sounds/status.mp3',
    _ => 'sounds/event.mp3',
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
