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
    String role = 'user',
  }) async {
    final res = await _auth.signUp(email: email, password: password);
    final id = res.user?.id;
    if (id == null) throw Exception('فشل إنشاء الحساب');

    // لو تأكيد الإيميل مفعّل، مفيش session نكتب بيها الـ profile.
    if (res.session == null) {
      throw Exception('افتح إيميلك وأكّد الحساب، وبعدين سجّل دخول');
    }

    final user = AppUser(id: id, name: name, email: email, phone: phone, role: role);
    await SupabaseService.table(_table).insert(user.toMap());
    return user;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // ممكن يكون إيميل أو رقم موبايل — لو رقم نحوّله لإيميل عبر RPC آمن.
    var loginEmail = email.trim();
    if (!loginEmail.contains('@')) {
      final resolved = await SupabaseService.client
          .rpc('email_for_phone', params: {'p': loginEmail});
      if (resolved == null || (resolved as String).isEmpty) {
        throw Exception('الرقم مش مسجّل');
      }
      loginEmail = resolved;
    }
    final res =
        await _auth.signInWithPassword(email: loginEmail, password: password);
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
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<bool> get authChanges =>
      _auth.onAuthStateChange.map((e) => e.session != null);

  Future<AppUser> _fetchProfile(String id) async {
    final row =
        await SupabaseService.table(_table).select().eq('id', id).single();
    return AppUser.fromMap(row);
  }
}
