import 'package:fantasy_5omasi/core/links/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('اللينك بيتحوّل لصفحة زي الإشعارات', () {
    expect(DeepLinks.toRoute(Uri.parse('khomasi://open?t=tournament&id=abc-1')), 'tournament:abc-1');
    expect(DeepLinks.toRoute(Uri.parse('https://rota259.github.io/khomasi/l/?t=join&id=K7Q2XZ')), 'join:K7Q2XZ');
  });

  test('لينك غريب مبيفتحش حاجة', () {
    expect(DeepLinks.toRoute(Uri.parse('khomasi://open?t=admin&id=logs')), isNull);
    expect(DeepLinks.toRoute(Uri.parse('khomasi://open?t=venue')), isNull);
  });

  test('لينك الشير بيعدّي على صفحة الويب', () {
    final u = DeepLinks.url('venue', 'v 1');
    expect(u, contains('/l/?t=venue&id=v+1'));
    expect(DeepLinks.toRoute(Uri.parse(u)), 'venue:v 1');
  });
}
