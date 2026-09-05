import 'models/app_user.dart';

/// عقد طبقة المصادقة — الـ ViewModel بيعتمد على ده مش على Supabase.
abstract interface class AuthRepository {
  /// تسجيل مستخدم جديد وإنشاء profile ليه.
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
  });

  /// تسجيل دخول بالإيميل.
  Future<AppUser> signIn({required String email, required String password});

  /// جلب بروفايل المستخدم الحالي (null لو مش مسجّل).
  Future<AppUser?> currentUser();

  /// تسجيل خروج.
  Future<void> signOut();

  /// بث تغيّر حالة الدخول (مسجّل/خارج).
  Stream<bool> get authChanges;
}
