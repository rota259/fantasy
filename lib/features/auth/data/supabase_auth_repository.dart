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
    if (res.session == null) {
      throw const AuthException('اتبعتلك رسالة على الإيميل — أكّد الحساب وبعدين سجّل دخول');
    }
    return _fetchProfile(id);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    // ممكن يكون إيميل أو رقم موبايل — لو رقم نحوّله لإيميل عبر RPC آمن.
    var loginEmail = email.trim();
    if (!loginEmail.contains('@')) {
      final resolved = await SupabaseService.client.rpc('email_for_phone', params: {'p': loginEmail});
      if (resolved == null || (resolved as String).isEmpty) {
        throw Exception('الرقم مش مسجّل');
      }
      loginEmail = resolved;
    }
    final res = await _auth.signInWithPassword(email: loginEmail, password: password);
    final id = res.user?.id;
    if (id == null) throw Exception('بيانات الدخول غير صحيحة');
    return _fetchProfile(id);
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
