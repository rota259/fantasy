import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    if (_live && zoneId == null) {
      emit(const AuthState(status: AuthStatus.error, message: 'اختار منطقتك'));
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

  String _msg(Object e) {
    if (e is AuthException) return e.message;
    return 'حصل خطأ، حاول تاني.';
  }
}
