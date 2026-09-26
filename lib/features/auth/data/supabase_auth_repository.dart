import 'package:supabase_flutter/supabase_flutter.dart';

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
    final res = await _auth.signUp(email: email, password: password);
    final id = res.user?.id;
    if (id == null) throw Exception('فشل إنشاء الحساب');

    // لو تأكيد الإيميل مفعّل، مفيش session نكتب بيها الـ profile.
    if (res.session == null) {
      throw Exception('افتح إيميلك وأكّد الحساب، وبعدين سجّل دخول');
    }

    final user = AppUser(id: id, name: name, email: email, phone: phone, zoneId: zoneId);
    await SupabaseService.table(_table).insert(user.toInsert());
    final code = referralCode?.trim() ?? '';
    if (code.isNotEmpty) {
      try {
        await SupabaseService.client.rpc('apply_referral', params: {'p_code': code});
      } catch (_) {} // كود غلط مش هيوقّف التسجيل
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
    await _auth.signOut();
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
