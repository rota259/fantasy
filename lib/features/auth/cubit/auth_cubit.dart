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
    } catch (e) {
      emit(AuthState(status: AuthStatus.error, message: _msg(e)));
    }
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
    if (password.length < 8) return 'كلمة السر ٨ حروف على الأقل';
    if (!password.contains(RegExp(r'[0-9]')) || !password.contains(RegExp(r'[A-Za-z]'))) {
      return 'كلمة السر لازم فيها حروف وأرقام';
    }
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

  String _msg(Object e) {
    if (e is AuthException) return e.message;
    return 'حصل خطأ، حاول تاني.';
  }
}
