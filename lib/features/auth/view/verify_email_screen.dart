import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/code_widgets.dart';

/// تأكيد الإيميل: الكود (٦ أرقام) اللي اتبعت على الإيميل → دخول.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});
  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy || _code.text.length != CodeField.length) return;
    FocusScope.of(context).unfocus();
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AuthCubit>().verifyEmail(widget.email, _code.text);
    if (!mounted) return;
    if (err == null) {
      nav.popUntil((r) => r.isFirst); // الدخول تم — الأبلكيشن بيفتح
    } else {
      setState(() {
        _busy = false;
        _error = err;
        _code.clear();
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
            Text('📩', textAlign: TextAlign.center, style: AppText.h(48)),
            const SizedBox(height: 8),
            Text('أكّد إيميلك', textAlign: TextAlign.center, style: AppText.h(22)),
            const SizedBox(height: 6),
            Text(
              'بعتنا كود من ٦ أرقام على\n${widget.email}',
              textAlign: TextAlign.center,
              style: AppText.body(13, color: AppColors.neutral700, height: 1.6),
            ),
            const SizedBox(height: 22),
            CodeField(controller: _code, onDone: _verify),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.body(12, color: AppColors.danger),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _busy ? null : _verify, child: Text(_busy ? 'بنتأكّد…' : 'أكّد')),
            ResendCodeButton(onResend: () => context.read<AuthCubit>().resendEmailCode(widget.email)),
            const SizedBox(height: 10),
            Text(
              'الكود صالح ١٠ دقايق. ماوصلش؟ بص في الـ Spam. ولو الإيميل ده متسجّل قبل كده مش هيوصلك كود — '
              'ارجع وسجّل دخول أو دوس «نسيت كلمة السر».',
              textAlign: TextAlign.center,
              style: AppText.body(11, color: AppColors.neutral600, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
