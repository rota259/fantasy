import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/google_auth.dart';
import '../../../core/supabase/supabase_service.dart';
import 'auth_repository.dart';
import 'models/app_user.dart';

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
  Future<AppUser> signIn({required String email, required String password}) async {
    final id = email.trim();
    // رقم موبايل: الدخول بيتعمل في السيرفر — إيميل الحساب مبيطلعش بره خالص
    if (!id.contains('@')) {
      final r = await _phone({'action': 'login', 'phone': id, 'password': password});
      return _enter(r);
    }
    try {
      final res = await _auth.signInWithPassword(email: id, password: password);
      final uid = res.user?.id;
      if (uid == null) throw const AuthException('الإيميل/الرقم أو كلمة السر غلط', code: 'invalid_credentials');
      return _fetchProfile(uid);
    } on AuthException catch (e) {
      // كلمة السر صح بس الإيميل لسه متأكّدش → نبعت كود جديد ونروح لشاشة الكود
      if (e.code == 'email_not_confirmed' || e.message.toLowerCase().contains('not confirmed')) {
        try {
          await resendEmailCode(id);
        } catch (_) {}
        throw EmailNotConfirmed(id);
      }
      rethrow;
    }
  }

  /// نداء فانكشن الدخول بالرقم. الأخطاء بترجع كـ AuthException بنفس أكواد Supabase.
  Future<Map<String, dynamic>> _phone(Map<String, dynamic> body) async {
    final Map<String, dynamic> data;
    try {
      final res = await SupabaseService.client.functions.invoke('auth-phone', body: body);
      data = Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      throw const AuthException('تعذّر الاتصال — جرّب تاني');
    }
    final err = data['error'] as String?;
    if (err == null) return data;
    // الكود اتستهلك بس كلمة السر مرفوضة: الجلسة رجعت → نكمّل التغيير من غير كود جديد
    final refresh = data['refresh_token'] as String?;
    if (refresh != null) await _auth.setSession(refresh);
    throw switch (err) {
      'too_many' => const AuthException('طلبت كتير — استنى ربع ساعة وجرّب تاني', code: 'over_request_rate_limit'),
      'email_not_confirmed' => const AuthException('إيميل الحساب لسه متأكّدش — سجّل دخول بالإيميل وأكّده بالكود'),
      'bad_code' => const AuthException('الكود غلط أو انتهى', code: 'otp_expired'),
      'weak_password' => const AuthException('كلمة السر ضعيفة', code: 'weak_password'),
      'same_password' => const AuthException('نفس القديمة', code: 'same_password'),
      _ => const AuthException('الإيميل/الرقم أو كلمة السر غلط', code: 'invalid_credentials'),
    };
  }

  /// الجلسة اللي رجعت من السيرفر → دخول.
  Future<AppUser> _enter(Map<String, dynamic> r) async {
    final refresh = r['refresh_token'] as String?;
    if (refresh == null) throw const AuthException('الإيميل/الرقم أو كلمة السر غلط', code: 'invalid_credentials');
    final res = await _auth.setSession(refresh);
    final uid = res.user?.id;
    if (uid == null) throw const AuthException('تعذّر الدخول — جرّب تاني');
    return _fetchProfile(uid);
  }

  @override
  Future<AppUser> verifyEmail(String email, String code) async {
    final res = await _auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.signup);
    final id = res.user?.id;
    if (id == null || res.session == null) throw const AuthException('الكود غلط أو انتهى');
    return _fetchProfile(id);
  }

  @override
  Future<void> resendEmailCode(String email) => _auth.resend(type: OtpType.signup, email: email.trim());

  @override
  Future<void> sendPasswordReset(String identifier) async {
    final id = identifier.trim();
    if (id.contains('@')) {
      await _auth.resetPasswordForEmail(id);
    } else {
      await _phone({'action': 'reset', 'phone': id}); // السيرفر بيبعت على إيميل الحساب — ومبيقولش موجود ولا لأ
    }
  }

  @override
  Future<AppUser> resetPassword(String identifier, String code, String newPassword) async {
    final id = identifier.trim();
    // الكود بيعمل session مؤقتة (لو اتعملت قبل كده والتغيير فشل، منتحققش تاني بكود مستهلك)
    if (_auth.currentSession == null) {
      if (!id.contains('@')) {
        final user = await _enter(
          await _phone({'action': 'reset_confirm', 'phone': id, 'code': code.trim(), 'password': newPassword}),
        );
        await _signOutOthers();
        return user;
      }
      final res = await _auth.verifyOTP(email: id, token: code.trim(), type: OtpType.recovery);
      if (res.session == null) throw const AuthException('الكود غلط أو انتهى', code: 'otp_expired');
    }
    final res = await _auth.updateUser(UserAttributes(password: newPassword));
    final uid = res.user?.id;
    if (uid == null) throw const AuthException('تعذّر تغيير كلمة السر');
    await _signOutOthers();
    return _fetchProfile(uid);
  }

  /// أي جهاز تاني كان داخل بالحساب بيتسجّل خروج.
  Future<void> _signOutOthers() async {
    try {
      await _auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    final g = await GoogleAuth.signIn();
    if (g == null) return null;
    final res = await _auth.signInWithIdToken(provider: OAuthProvider.google, idToken: g.idToken, nonce: g.nonce);
    final id = res.user?.id;
    if (id == null) throw const AuthException('فشل الدخول بجوجل');
    return _fetchProfile(id);
  }

  @override
  Future<AppUser?> currentUser() async {
    final id = _auth.currentUser?.id;
    if (id == null) return null;
    return _fetchProfile(id);
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

  /// بروفايلي كامل (الإيميل والموبايل مخفيين عن غيري — بيجوا من دالة my_profile).
  Future<AppUser> _fetchProfile(String id) async {
    final rows = await SupabaseService.client.rpc('my_profile') as List;
    if (rows.isEmpty) throw Exception('البروفايل مش موجود');
    return AppUser.fromMap(rows.first as Map<String, dynamic>);
  }
}
