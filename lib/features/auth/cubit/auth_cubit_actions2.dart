part of 'auth_cubit.dart';

extension AuthCubitSections2 on AuthCubit {
  /// حذف الحساب نهائيًا — بيرجّع رسالة خطأ أو null لو اتمسح.
  Future<String?> deleteAccount() async {
    if (!_live) return null;
    try {
      await _repo.deleteAccount();
      AppLog.info('auth.account.deleted');
      _emit(const AuthState(status: AuthStatus.unauthenticated));
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
      'captcha_failed' => 'التحقق إنك مش روبوت فشل — جرّب تاني',
      _ when m.contains('captcha') => 'التحقق إنك مش روبوت فشل — جرّب تاني',
      _ when m.contains('invalid login') => 'الإيميل/الرقم أو كلمة السر غلط',
      _ when m.contains('expired') || m.contains('invalid') && m.contains('token') =>
        'الكود غلط أو انتهى — اطلب كود جديد',
      _ when m.contains('rate limit') || m.contains('security purposes') => 'طلبت كتير — استنى شوية وجرّب تاني',
      _ => e.message,
    };
  }

  /// الدخول بجوجل (اليوزر الجديد بيتعمله حساب، ولو ملوش منطقة بيختارها بعدها).
  Future<void> signInWithGoogle() async {
    _emit(const AuthState(status: AuthStatus.authenticating));
    try {
      final user = await _repo.signInWithGoogle();
      if (user != null) AppLog.info('auth.login.success', fields: {'method': 'google'});
      _emit(
        user == null
            ? const AuthState(status: AuthStatus.unauthenticated)
            : AuthState(status: AuthStatus.authenticated, user: user),
      );
    } catch (e) {
      AppLog.warn('auth.login.failed', error: e, fields: {'method': 'google'});
      _emit(AuthState(status: AuthStatus.error, message: e is AuthException ? e.message : 'الدخول بجوجل فشل'));
    }
  }
}
