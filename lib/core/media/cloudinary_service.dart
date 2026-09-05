import 'dart:convert';

import 'package:http/http.dart' as http;

/// رفع الصور إلى Cloudinary (unsigned upload) وإرجاع الرابط.
abstract final class CloudinaryService {
  CloudinaryService._();

  static const _cloudName = 'dmsfxoble';
  static const _uploadPreset = 'fantasy';

  static Uri get _endpoint =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  /// بترفع صورة من مسار محلي وبترجّع secure_url.
  static Future<String> uploadImage(String filePath) async {
    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final data = json.decode(body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['secure_url'] != null) {
      return data['secure_url'] as String;
    }
    throw Exception('فشل رفع الصورة إلى Cloudinary');
  }
}
