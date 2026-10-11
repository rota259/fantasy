import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/code_widgets.dart';
import '../widgets/login_field.dart';

/// نسيت كلمة السر — خطوتين:
///   ١) الإيميل أو رقم الموبايل → كود (٦ أرقام) بيتبعت على إيميل الحساب.
///   ٢) الكود + كلمة السر الجديدة → دخول (وباقي الأجهزة بتتسجّل خروج).
/// الشاشة مبتقولش الحساب موجود ولا لأ: الرسالة واحدة في الحالتين.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initial = ''});
  final String initial; // اللي كان مكتوب في شاشة الدخول

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _id = TextEditingController(text: widget.initial);
  final _code = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_id, _code, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<String?> _send() => context.read<AuthCubit>().sendPasswordReset(_id.text);

  Future<void> _start() async {
    if (_id.text.trim().length < 5) return setState(() => _error = 'اكتب الإيميل أو رقم الموبايل');
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await _send();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
      _sent = err == null;
    });
  }

  Future<void> _reset() async {
    if (_code.text.length != CodeField.length) return setState(() => _error = 'اكتب الكود (٦ أرقام)');
    if (_pass.text != _pass2.text) return setState(() => _error = 'كلمتين السر مش زي بعض');
    final weak = AuthCubit.passwordProblem(_pass.text);
    if (weak != null) return setState(() => _error = weak);
    FocusScope.of(context).unfocus();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AuthCubit>().resetPassword(_id.text, _code.text, _pass.text);
    if (!mounted) return;
    if (err == null) {
      messenger.showSnackBar(const SnackBar(content: Text('كلمة السر اتغيّرت ✓')));
      nav.popUntil((r) => r.isFirst);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0, foregroundColor: AppColors.ink),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 26),
          children: [
            Text('🔑', textAlign: TextAlign.center, style: AppText.h(48)),
            const SizedBox(height: 8),
            Text('نسيت كلمة السر؟', textAlign: TextAlign.center, style: AppText.h(22)),
            const SizedBox(height: 6),
            Text(
              _sent
                  ? 'لو فيه حساب بالبيانات دي، هيوصل كود من ٦ أرقام على إيميله خلال دقيقة. اكتبه واختار كلمة سر جديدة.'
                  : 'اكتب إيميلك أو رقم موبايلك، وهنبعت كود على إيميل الحساب.',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.neutral700, height: 1.6),
            ),
            const SizedBox(height: 22),
            if (!_sent)
              LoginField(label: 'رقم الموبايل أو الإيميل', hint: '01xx xxx xxxx', controller: _id)
            else ...[
              CodeField(controller: _code),
              const SizedBox(height: 14),
              LoginField(label: 'كلمة السر الجديدة', hint: '٨ حروف فيها حروف وأرقام', obscure: true, controller: _pass),
              const SizedBox(height: 14),
              LoginField(label: 'اكتبها تاني', hint: '••••••••', obscure: true, controller: _pass2),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.body(12, color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : (_sent ? _reset : _start),
              child: Text(_busy ? 'لحظة…' : (_sent ? 'غيّر كلمة السر' : 'ابعت الكود')),
            ),
            if (_sent) ...[
              ResendCodeButton(onResend: _send),
              Text(
                'الكود صالح ١٠ دقايق. ماوصلش؟ بص في الـ Spam. لو مسجّل بجوجل ادخل بزرار جوجل على طول.',
                textAlign: TextAlign.center,
                style: AppText.body(11, color: AppColors.neutral600, height: 1.6),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
