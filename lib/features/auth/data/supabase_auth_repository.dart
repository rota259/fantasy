import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/captcha.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/auth/google_auth.dart';
import '../../../core/supabase/supabase_service.dart';
import 'auth_repository.dart';
import 'models/app_user.dart';
import 'profile_cache.dart';

part 'supabase_auth_repository_sections.dart';

/// تنفيذ AuthRepository فوق Supabase Auth + جدول profiles.
class SupabaseAuthRepository implements AuthRepository {
  static const _table = 'profiles';

  GoTrueClient get _auth => SupabaseService.client.auth;

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
    int? zoneId,
  }) async {
    // رقم موبايل واحد لحساب واحد (قبل ما نعمل الحساب عشان مايفضلش حساب ناقص)
    final p = phone?.trim() ?? '';
    if (p.isNotEmpty && await SupabaseService.client.rpc('phone_taken', params: {'p': p}) == true) {
      throw const AuthException('الرقم ده متسجّل بحساب تاني');
    }
    // البروفايل بيتعمل في السيرفر من البيانات دي (handle_new_user) — حتى لو تأكيد الإيميل مفعّل
    final res = await _auth.signUp(
      email: email,
      password: password,
      captchaToken: await Captcha.token(),
      data: {
        'name': name,
        'phone': p,
        'zone_id': zoneId,
        if (referralCode != null && referralCode.trim().isNotEmpty) 'ref_code': referralCode.trim(),
      },
    );
    final id = res.user?.id;
    if (id == null) throw const AuthException('فشل إنشاء الحساب');
    // تأكيد الإيميل مفعّل: الكود اتبعت على الإيميل → شاشة الكود
    if (res.session == null) throw EmailNotConfirmed(email);
    return _fetchProfile(id);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) => _signIn(email, password);

  @override
  Future<AppUser> verifyEmail(String email, String code) async {
    final res = await _auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.signup,
      captchaToken: await Captcha.token(),
    );
    final id = res.user?.id;
    if (id == null || res.session == null) throw const AuthException('الكود غلط أو انتهى');
    return _fetchProfile(id);
  }

  @override
  Future<void> resendEmailCode(String email) async =>
      _auth.resend(type: OtpType.signup, email: email.trim(), captchaToken: await Captcha.token());

  @override
  Future<void> sendPasswordReset(String identifier) async {
    final id = identifier.trim();
    if (id.contains('@')) {
      await _auth.resetPasswordForEmail(id, captchaToken: await Captcha.token());
    } else {
      await _phone({'action': 'reset', 'phone': id}); // السيرفر بيبعت على إيميل الحساب — ومبيقولش موجود ولا لأ
    }
  }

  @override
  Future<AppUser> resetPassword(String identifier, String code, String newPassword) =>
      _resetPassword(identifier, code, newPassword);

  @override
  Future<AppUser?> signInWithGoogle() async {
    final g = await GoogleAuth.signIn();
    if (g == null) return null;
    final res = await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: g.idToken,
      nonce: g.nonce,
      captchaToken: await Captcha.token(),
    );
    final id = res.user?.id;
    if (id == null) throw const AuthException('فشل الدخول بجوجل');
    return _fetchProfile(id);
  }

  @override
  Future<AppUser?> currentUser() async {
    final id = _auth.currentUser?.id;
    if (id == null) return null;
    try {
      return await _fetchProfile(id);
    } on AuthException {
      rethrow; // الجلسة نفسها مبقتش صالحة → يسجّل دخول تاني
    } catch (e) {
      // النت بطيء أو مقطوع وقت الفتح: الجلسة سليمة → ندخل بآخر بروفايل محفوظ بدل شاشة الدخول
      final cached = await ProfileCache.read(id);
      if (cached == null) rethrow;
      AppLog.warn('auth.profile.from_cache', error: e);
      return AppUser.fromMap(cached);
    }
  }

  @override
  Future<void> signOut() async {
    // الجهاز ده ميستقبلش إشعارات الحساب بعد الخروج
    final id = _auth.currentUser?.id;
    if (id != null) {
      try {
        await SupabaseService.table(_table).update({'fcm_token': null}).eq('id', id);
      } catch (_) {}
    }
    await GoogleAuth.signOut();
    await ProfileCache.clear();
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final id = _auth.currentUser?.id;
    if (id == null) return;
    // الصور الأول (الـ SQL مينفعش يمسح ملفات)، وبعدين الحساب وكل بياناته في السيرفر
    try {
      final storage = SupabaseService.client.storage.from('avatars');
      final files = await storage.list(path: id);
      if (files.isNotEmpty) await storage.remove([for (final f in files) '$id/${f.name}']);
    } catch (_) {} // الصور مش هتوقّف الحذف
    await SupabaseService.client.rpc('delete_my_account');
    try {
      await _auth.signOut();
    } catch (_) {} // الحساب اتمسح أصلًا
  }

  @override
  Stream<bool> get authChanges => _auth.onAuthStateChange.map((e) => e.session != null);
}
