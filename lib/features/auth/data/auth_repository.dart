import 'models/app_user.dart';

/// الحساب اتعمل بس الإيميل لسه متأكّدش — لازم الكود اللي اتبعت عليه.
class EmailNotConfirmed implements Exception {
  const EmailNotConfirmed(this.email);
  final String email;
}

/// عقد طبقة المصادقة — الـ ViewModel بيعتمد على ده مش على Supabase.
abstract interface class AuthRepository {
  /// تسجيل مستخدم جديد وإنشاء profile ليه (+ كود دعوة صاحبه لو موجود).
  /// بيرمي [EmailNotConfirmed] لو تأكيد الإيميل مفعّل (الكود اتبعت على الإيميل).
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

  /// تسجيل دخول بالإيميل أو الموبايل. بيرمي [EmailNotConfirmed] لو الإيميل لسه متأكّدش.
  Future<AppUser> signIn({required String email, required String password});

  /// تأكيد الإيميل بالكود اللي اتبعت عليه (٦ أرقام) → دخول.
  Future<AppUser> verifyEmail(String email, String code);

  /// ابعت كود تأكيد الإيميل تاني.
  Future<void> resendEmailCode(String email);

  /// نسيت كلمة السر: ابعت كود على إيميل الحساب. [identifier] إيميل أو رقم موبايل —
  /// الرقم بيتحوّل لإيميل في السيرفر بس (مبيرجعش للأبلكيشن)، ومبنقولش الحساب موجود ولا لأ.
  Future<void> sendPasswordReset(String identifier);

  /// كلمة سر جديدة بالكود اللي وصل على الإيميل → دخول (وباقي الأجهزة بتتسجّل خروج).
  /// [identifier] نفس اللي اتكتب في [sendPasswordReset].
  Future<AppUser> resetPassword(String identifier, String code, String newPassword);

  /// جلب بروفايل المستخدم الحالي (null لو مش مسجّل).
  Future<AppUser?> currentUser();

  /// تسجيل خروج.
  Future<void> signOut();

  /// حذف الحساب نهائيًا (الصور + كل البيانات) — Apple و Google بيطلبوه.
  Future<void> deleteAccount();

  /// بث تغيّر حالة الدخول (مسجّل/خارج).
  Stream<bool> get authChanges;
}
