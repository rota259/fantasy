import 'models/app_user.dart';

/// عقد طبقة المصادقة — الـ ViewModel بيعتمد على ده مش على Supabase.
abstract interface class AuthRepository {
  /// تسجيل مستخدم جديد وإنشاء profile ليه (+ كود دعوة صاحبه لو موجود).
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
    int? zoneId,
  });

  /// الدخول بجوجل — null لو اليوزر لغى. الحساب الجديد بيتعمل لوحده (والمنطقة بيختارها بعدها).
  Future<AppUser?> signInWithGoogle();

  /// تسجيل دخول بالإيميل.
  Future<AppUser> signIn({required String email, required String password});

  /// جلب بروفايل المستخدم الحالي (null لو مش مسجّل).
  Future<AppUser?> currentUser();

  /// تسجيل خروج.
  Future<void> signOut();

  /// حذف الحساب نهائيًا (الصور + كل البيانات) — Apple و Google بيطلبوه.
  Future<void> deleteAccount();

  /// بث تغيّر حالة الدخول (مسجّل/خارج).
  Stream<bool> get authChanges;
}
