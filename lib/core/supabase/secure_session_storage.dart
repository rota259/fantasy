import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/app_log.dart';

/// التخزين المشفّر لجلسة الدخول (بدل الملف العادي اللي Supabase بيستخدمه لوحده).
///   أندرويد: التوكن بيتشفّر بـ AES-GCM بمفتاح محفوظ في Android Keystore (عتاد الموبايل) —
///   حتى لو حد قرا ملفات الأبلكيشن (موبايل متعمله root مثلًا) مش هيقدر يفك التوكن.
///   آيفون: Keychain (بعد أول فتح للموبايل، ومبيتنقلش لجهاز تاني).
/// لو التشفير باظ على جهاز (مفتاح اتمسح بعد استرجاع نسخة مثلًا): البيانات بتتمسح واليوزر يدخل تاني — مفيش crash.
const _secure = FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: true, storageNamespace: 'khomasi_auth'),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

/// الجلسة نفسها (access + refresh token).
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this.key);

  /// نفس اسم المفتاح اللي Supabase كان بيستخدمه: `sb-<project>-auth-token`.
  final String key;

  /// أول مرة بعد التحديث: الجلسة القديمة (الملف العادي) بتتنقل للمشفّر وتتمسح من مكانها — اليوزر ميخرجش.
  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final old = prefs.getString(key);
      if (old == null) return;
      if (await _secure.read(key: key) == null) await _secure.write(key: key, value: old);
      await prefs.remove(key);
      AppLog.info('auth.session.migrated_to_secure');
    } catch (e) {
      AppLog.warn('auth.session.migrate_failed', error: e);
    }
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _secure.read(key: key);
    } catch (e) {
      // التشفير باظ على الجهاز ده: نبدأ من جديد (اليوزر يدخل تاني) بدل ما الأبلكيشن يقف
      AppLog.warn('auth.session.read_failed', error: e);
      await removePersistedSession();
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _secure.write(key: key, value: persistSessionString);
    } catch (e) {
      AppLog.error('auth.session.write_failed', error: e);
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _secure.delete(key: key);
    } catch (_) {}
  }
}

/// كود الـ PKCE المؤقت (بيتحفظ لحظات وقت الدخول بجوجل/الروابط) — برضه مشفّر.
class SecurePkceStorage extends GotrueAsyncStorage {
  const SecurePkceStorage();

  @override
  Future<String?> getItem({required String key}) async {
    try {
      return await _secure.read(key: 'pkce_$key');
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setItem({required String key, required String value}) => _secure.write(key: 'pkce_$key', value: value);

  @override
  Future<void> removeItem({required String key}) async {
    try {
      await _secure.delete(key: 'pkce_$key');
    } catch (_) {}
  }
}
