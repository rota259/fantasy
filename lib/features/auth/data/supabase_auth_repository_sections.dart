part of 'supabase_auth_repository.dart';

extension _SupabaseAuthRepositorySections1 on SupabaseAuthRepository {
  /// نداء فانكشن الدخول بالرقم. الأخطاء بترجع كـ AuthException بنفس أكواد Supabase.
  Future<Map<String, dynamic>> _phone(Map<String, dynamic> body) async {
    final Map<String, dynamic> data;
    try {
      final captcha = await Captcha.token(); // السيرفر بيبعته لـ Supabase Auth مع الطلب
      final res = await SupabaseService.client.functions.invoke(
        'auth-phone',
        body: {...body, 'captcha_token': ?captcha},
      );
      data = Map<String, dynamic>.from(res.data as Map);
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('تعذّر الاتصال — جرّب تاني');
    }
    final err = data['error'] as String?;
    if (err == null) return data;
    // الكود اتستهلك بس كلمة السر مرفوضة: الجلسة رجعت → نكمّل التغيير من غير كود جديد
    final refresh = data['refresh_token'] as String?;
    if (refresh != null) await _auth.setSession(refresh);
    throw switch (err) {
      'too_many' => const AuthException('طلبت كتير — استنى ربع ساعة وجرّب تاني', code: 'over_request_rate_limit'),
      'email_not_confirmed' => const AuthException('إيميل الحساب لسه متأكّدش — سجّل دخول بالإيميل وأكّده بالكود'),
      'bad_code' => const AuthException('الكود غلط أو انتهى', code: 'otp_expired'),
      'weak_password' => const AuthException('كلمة السر ضعيفة', code: 'weak_password'),
      'same_password' => const AuthException('نفس القديمة', code: 'same_password'),
      'captcha' => const AuthException('التحقق إنك مش روبوت فشل — جرّب تاني', code: 'captcha_failed'),
      _ => const AuthException('الإيميل/الرقم أو كلمة السر غلط', code: 'invalid_credentials'),
    };
  }

  /// الجلسة اللي رجعت من السيرفر → دخول.
  Future<AppUser> _enter(Map<String, dynamic> r) async {
    final refresh = r['refresh_token'] as String?;
    if (refresh == null) throw const AuthException('الإيميل/الرقم أو كلمة السر غلط', code: 'invalid_credentials');
    final res = await _auth.setSession(refresh);
    final uid = res.user?.id;
    if (uid == null) throw const AuthException('تعذّر الدخول — جرّب تاني');
    return _fetchProfile(uid);
  }

  /// أي جهاز تاني كان داخل بالحساب بيتسجّل خروج.
  Future<void> _signOutOthers() async {
    try {
      await _auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  /// بروفايلي كامل (الإيميل والموبايل مخفيين عن غيري — بيجوا من دالة my_profile).
  Future<AppUser> _fetchProfile(String id) async {
    final rows = await SupabaseService.client.rpc('my_profile') as List;
    if (rows.isEmpty) throw Exception('البروفايل مش موجود');
    final row = Map<String, dynamic>.from(rows.first as Map);
    await ProfileCache.save(id, row);
    return AppUser.fromMap(row);
  }

  /// الدخول بالإيميل أو برقم الموبايل.
  Future<AppUser> _signIn(String email, String password) async {
    final id = email.trim();
    // رقم موبايل: الدخول بيتعمل في السيرفر — إيميل الحساب مبيطلعش بره خالص
    if (!id.contains('@')) {
      final r = await _phone({'action': 'login', 'phone': id, 'password': password});
      return _enter(r);
    }
    try {
      final res = await _auth.signInWithPassword(email: id, password: password, captchaToken: await Captcha.token());
      final uid = res.user?.id;
      if (uid == null) throw const AuthException('الإيميل/الرقم أو كلمة السر غلط', code: 'invalid_credentials');
      return _fetchProfile(uid);
    } on AuthException catch (e) {
      // كلمة السر صح بس الإيميل لسه متأكّدش → نبعت كود جديد ونروح لشاشة الكود
      if (e.code == 'email_not_confirmed' || e.message.toLowerCase().contains('not confirmed')) {
        try {
          await resendEmailCode(id);
        } catch (_) {}
        throw EmailNotConfirmed(id);
      }
      rethrow;
    }
  }

  /// كلمة سر جديدة بالكود (إيميل مباشرة · رقم عن طريق السيرفر).
  Future<AppUser> _resetPassword(String identifier, String code, String newPassword) async {
    final id = identifier.trim();
    // الكود بيعمل session مؤقتة (لو اتعملت قبل كده والتغيير فشل، منتحققش تاني بكود مستهلك)
    if (_auth.currentSession == null) {
      if (!id.contains('@')) {
        final user = await _enter(
          await _phone({'action': 'reset_confirm', 'phone': id, 'code': code.trim(), 'password': newPassword}),
        );
        await _signOutOthers();
        return user;
      }
      final res = await _auth.verifyOTP(
        email: id,
        token: code.trim(),
        type: OtpType.recovery,
        captchaToken: await Captcha.token(),
      );
      if (res.session == null) throw const AuthException('الكود غلط أو انتهى', code: 'otp_expired');
    }
    final res = await _auth.updateUser(UserAttributes(password: newPassword));
    final uid = res.user?.id;
    if (uid == null) throw const AuthException('تعذّر تغيير كلمة السر');
    await _signOutOthers();
    return _fetchProfile(uid);
  }
}
