import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// نتيجة بحث عن مكان.
typedef Place = ({String name, LatLng point});

/// بحث عن أماكن في مصر باسمها (OpenStreetMap Nominatim — مجاني ومن غير مفتاح).
/// سياسة الاستخدام: طلب واحد في الثانية بالكتير + User-Agent واضح — والبحث هنا بس لما المدير يدوس بحث.
abstract final class GeoSearch {
  GeoSearch._();

  static Future<List<Place>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'json',
      'limit': '6',
      'countrycodes': 'eg',
      'accept-language': 'ar',
    });
    final res = await http.get(uri, headers: {'User-Agent': 'khomasi-fantasy/1.0 (com.example.fantasy_5omasi)'});
    if (res.statusCode != 200) return const [];
    final list = jsonDecode(res.body) as List;
    return [
      for (final r in list)
        (
          name: (r['display_name'] ?? '') as String,
          point: LatLng(double.parse(r['lat'] as String), double.parse(r['lon'] as String)),
        ),
    ];
  }
}
