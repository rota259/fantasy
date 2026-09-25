import 'package:fantasy_5omasi/features/awards/data/video_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('يوتيوب بكل أشكاله', () {
    expect(VideoLink.youtubeId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(VideoLink.youtubeId('https://youtu.be/dQw4w9WgXcQ?si=x'), 'dQw4w9WgXcQ');
    expect(VideoLink.youtubeId('https://youtube.com/shorts/abcDEF12345'), 'abcDEF12345');
    expect(VideoLink.thumbnail('https://youtu.be/dQw4w9WgXcQ'), 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg');
  });

  test('لينكات تانية مقبولة من غير صورة', () {
    expect(VideoLink.isValid('https://www.tiktok.com/@x/video/123'), isTrue);
    expect(VideoLink.thumbnail('https://www.tiktok.com/@x/video/123'), isNull);
  });

  test('لينكات مرفوضة', () {
    expect(VideoLink.isValid('javascript:alert(1)'), isFalse);
    expect(VideoLink.isValid('https://evil.com/video'), isFalse);
    expect(VideoLink.isValid('youtube'), isFalse);
  });
}
