import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/auth_repository.dart';
import '../data/models/app_user.dart';

part 'auth_state.dart';

/// ViewModel للمصادقة. لو Supabase مش متظبّط بيشتغل في وضع demo (بيعدّي بدون باك-إند).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  bool get _live => SupabaseConfig.isConfigured;

  /// تسجيل دخول تلقائي لو فيه session محفوظة.
  Future<void> checkSession() async {
    if (!_live) return;
    try {
      final user = await _repo.currentUser();
      emit(AuthState(status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated, user: user));
    } catch (_) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthState(status: AuthStatus.authenticating));
    if (!_live) {
      emit(const AuthState(status: AuthStatus.authenticated));
      return;
    }
    try {
      final user = await _repo.signIn(email: email.trim(), password: password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on EmailNotConfirmed catch (e) {
      emit(AuthState(status: AuthStatus.verifyEmail, pendingEmail: e.email));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, message: _msg(e)));
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? referralCode,
    int? zoneId,
  }) async {
    final err = _validateSignUp(name, password, zoneId);
    if (_live && err != null) {
      emit(AuthState(status: AuthStatus.error, message: err));
      return;
    }
    emit(const AuthState(status: AuthStatus.authenticating));
    if (!_live) {
      emit(const AuthState(status: AuthStatus.authenticated));
      return;
    }
    try {
      final user = await _repo.signUp(
        name: name.trim(),
        email: email.trim(),
        password: password,
        phone: phone,
        referralCode: referralCode,
        zoneId: zoneId,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on EmailNotConfirmed catch (e) {
      emit(AuthState(status: AuthStatus.verifyEmail, pendingEmail: e.email));
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, message: _msg(e)));
    }
  }

  /// تأكيد الإيميل بالكود → دخول. بيرجّع رسالة خطأ أو null.
  Future<String?> verifyEmail(String email, String code) async {
    try {
      final user = await _repo.verifyEmail(email, code);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// كود تأكيد جديد. بيرجّع رسالة خطأ أو null.
  Future<String?> resendEmailCode(String email) async {
    try {
      await _repo.resendEmailCode(email);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// نسيت كلمة السر: ابعت الكود على إيميل الحساب (إيميل أو رقم). بيرجّع رسالة خطأ أو null —
  /// ومن غير خطأ لو الحساب مش موجود (الشاشة مبتقولش).
  Future<String?> sendPasswordReset(String identifier) async {
    try {
      await _repo.sendPasswordReset(identifier);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// كلمة سر جديدة بالكود → دخول. بيرجّع رسالة خطأ أو null.
  Future<String?> resetPassword(String identifier, String code, String password) async {
    final weak = passwordProblem(password);
    if (weak != null) return weak;
    try {
      final user = await _repo.resetPassword(identifier, code, password);
      emit(AuthState(status: AuthStatus.authenticated, user: user));
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// شروط كلمة السر (نفسها في التسجيل وفي التغيير).
  static String? passwordProblem(String password) {
    if (password.length < 8) return 'كلمة السر ٨ حروف على الأقل';
    if (!password.contains(RegExp(r'[0-9]')) || !password.contains(RegExp(r'[A-Za-z]'))) {
      return 'كلمة السر لازم فيها حروف وأرقام';
    }
    return null;
  }

  /// إعادة تحميل البروفايل (بعد تغيير الصورة مثلًا).
  Future<void> refresh() async {
    if (!_live || state.user == null) return;
    try {
      final user = await _repo.currentUser();
      if (user != null) emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {}
  }

  Future<void> signOut() async {
    if (_live) {
      try {
        await _repo.signOut();
      } catch (_) {}
    }
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// شروط التسجيل قبل ما نكلّم السيرفر.
  static String? _validateSignUp(String name, String password, int? zoneId) {
    if (name.trim().length < 2 || name.trim().length > 40) return 'الاسم من ٢ لـ ٤٠ حرف';
    final weak = passwordProblem(password);
    if (weak != null) return weak;
    if (zoneId == null) return 'اختار منطقتك';
    return null;
  }

  /// الدخول بجوجل (اليوزر الجديد بيتعمله حساب، ولو ملوش منطقة بيختارها بعدها).
  Future<void> signInWithGoogle() async {
    emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final user = await _repo.signInWithGoogle();
      emit(
        user == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, user: user),
      );
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, message: e is AuthException ? e.message : 'الدخول بجوجل فشل'));
    }
  }

  /// حذف الحساب نهائيًا — بيرجّع رسالة خطأ أو null لو اتمسح.
  Future<String?> deleteAccount() async {
    if (!_live) return null;
    try {
      await _repo.deleteAccount();
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return null;
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر حذف الحساب — جرّب تاني');
    }
  }

  /// رسائل السيرفر بالعربي — ومن غير ما نقول الحساب موجود ولا لأ.
  String _msg(Object e) {
    if (e is! AuthException) return 'حصل خطأ، حاول تاني.';
    final m = e.message.toLowerCase();
    return switch (e.code) {
      'invalid_credentials' => 'الإيميل/الرقم أو كلمة السر غلط',
      'otp_expired' || 'otp_disabled' => 'الكود غلط أو انتهى — اطلب كود جديد',
      'over_email_send_rate_limit' || 'over_request_rate_limit' => 'طلبت كتير — استنى شوية وجرّب تاني',
      'weak_password' => 'كلمة السر ضعيفة — ٨ حروف على الأقل فيها حروف وأرقام',
      'same_password' => 'دي نفس كلمة السر القديمة — اختار واحدة جديدة',
      'email_address_invalid' || 'validation_failed' => 'الإيميل مش صحيح',
      'user_already_exists' || 'email_exists' => 'الإيميل ده متسجّل قبل كده — سجّل دخول',
      _ when m.contains('invalid login') => 'الإيميل/الرقم أو كلمة السر غلط',
      _ when m.contains('expired') || m.contains('invalid') && m.contains('token') =>
        'الكود غلط أو انتهى — اطلب كود جديد',
      _ when m.contains('rate limit') || m.contains('security purposes') => 'طلبت كتير — استنى شوية وجرّب تاني',
      _ => e.message,
    };
  }
}
