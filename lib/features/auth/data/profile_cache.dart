import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// آخر بروفايل اتجاب من السيرفر — متشفّر على الموبايل (زي جلسة الدخول).
/// لما الأبلكيشن يفتح والنت بطيء أو مقطوع، اليوزر بيدخل بيه على طول بدل ما يتطلب منه يسجّل دخول تاني،
/// والبروفايل بيتحدّث من السيرفر أول ما النت يرجع.
abstract final class ProfileCache {
  static const _store = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: true, storageNamespace: 'khomasi_auth'),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static const _key = 'profile_cache';

  static Future<void> save(String userId, Map<String, dynamic> row) async {
    try {
      await _store.write(key: _key, value: jsonEncode({'id': userId, 'row': row}));
    } catch (_) {}
  }

  /// البروفايل المحفوظ لليوزر ده بس (لو حساب تاني دخل على نفس الموبايل → null).
  static Future<Map<String, dynamic>?> read(String userId) async {
    try {
      final raw = await _store.read(key: _key);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m['id'] == userId ? Map<String, dynamic>.from(m['row'] as Map) : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      await _store.delete(key: _key);
    } catch (_) {}
  }
}
