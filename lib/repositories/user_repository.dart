import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:fantasy_5omasi/models/user_model.dart';

class UserRepository {
  static final _firestore = FirebaseFirestore.instance;

  /// تحديث بيانات المستخدم في Firestore
  static Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  /// رفع صورة إلى Cloudinary واسترجاع الرابط
  static Future<String> uploadToCloudinary(String imagePath) async {
    const cloudName = 'dmsfxoble'; // ← غيّرها حسب حسابك
    const uploadPreset = 'fantasy'; // ← غيّرها حسب إعداداتك

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imagePath));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = json.decode(resBody);

    if (response.statusCode == 200 && data['secure_url'] != null) {
      return data['secure_url'];
    } else {
      throw Exception('فشل رفع الصورة إلى Cloudinary');
    }
  }
}
