part of 'auth_cubit.dart';

extension AuthCubitSections1 on AuthCubit {
  /// تسجيل دخول تلقائي لو فيه session محفوظة.
  Future<void> checkSession() async {
    if (!_live) return;
    // النت ممكن يكون لسه مجاش وقت الفتح: ٣ محاولات قبل ما نعتبره مش مسجّل
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final user = await _repo.currentUser();
        _emit(AuthState(status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated, user: user));
        return;
      } on AuthException {
        break; // الجلسة نفسها انتهت
      } catch (_) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    _emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> signIn(String email, String password) async {
    _emit(const AuthState(status: AuthStatus.authenticating));
    if (!_live) {
      _emit(const AuthState(status: AuthStatus.authenticated));
      return;
    }
    try {
      final user = await _repo.signIn(email: email.trim(), password: password);
      AppLog.info('auth.login.success', fields: {'method': 'password'});
      _emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on EmailNotConfirmed catch (e) {
      _emit(AuthState(status: AuthStatus.verifyEmail, pendingEmail: e.email));
    } catch (e) {
      AppLog.warn('auth.login.failed', error: e, fields: {'method': 'password'});
      _emit(AuthState(status: AuthStatus.error, message: _msg(e)));
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
    final err = AuthCubit._validateSignUp(name, password, zoneId);
    if (_live && err != null) {
      _emit(AuthState(status: AuthStatus.error, message: err));
      return;
    }
    _emit(const AuthState(status: AuthStatus.authenticating));
    if (!_live) {
      _emit(const AuthState(status: AuthStatus.authenticated));
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
      AppLog.info('auth.signup.success');
      _emit(AuthState(status: AuthStatus.authenticated, user: user));
    } on EmailNotConfirmed catch (e) {
      AppLog.info('auth.signup.pending_email');
      _emit(AuthState(status: AuthStatus.verifyEmail, pendingEmail: e.email));
    } catch (e) {
      AppLog.warn('auth.signup.failed', error: e);
      _emit(AuthState(status: AuthStatus.error, message: _msg(e)));
    }
  }

  /// تأكيد الإيميل بالكود → دخول. بيرجّع رسالة خطأ أو null.
  Future<String?> verifyEmail(String email, String code) async {
    try {
      final user = await _repo.verifyEmail(email, code);
      _emit(AuthState(status: AuthStatus.authenticated, user: user));
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
      AppLog.info('auth.password_reset.requested');
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  /// كلمة سر جديدة بالكود → دخول. بيرجّع رسالة خطأ أو null.
  Future<String?> resetPassword(String identifier, String code, String password) async {
    final weak = AuthCubit.passwordProblem(password);
    if (weak != null) return weak;
    try {
      final user = await _repo.resetPassword(identifier, code, password);
      AppLog.info('auth.password_reset.done');
      _emit(AuthState(status: AuthStatus.authenticated, user: user));
      return null;
    } catch (e) {
      AppLog.warn('auth.password_reset.failed', error: e);
      return _msg(e);
    }
  }

  /// إعادة تحميل البروفايل (بعد تغيير الصورة مثلًا).
  Future<void> refresh() async {
    if (!_live || state.user == null) return;
    try {
      final user = await _repo.currentUser();
      if (user != null) _emit(AuthState(status: AuthStatus.authenticated, user: user));
    } catch (_) {}
  }

  Future<void> signOut() async {
    AppLog.info('auth.logout');
    if (_live) {
      try {
        await _repo.signOut();
      } catch (_) {}
    }
    _emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
