import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/login_field.dart';
import '../widgets/login_header.dart';

/// شاشة تسجيل الدخول — موصولة بـ AuthCubit (دخول حقيقي عند تظبيط Supabase).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _id = TextEditingController();
  final _pass = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _signIn() {
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signIn(_id.text, _pass.text);
  }

  void _social() {
    if (SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الدخول بجوجل/آبل قريباً')),
      );
    } else {
      context.read<AuthCubit>().signIn('', ''); // وضع demo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const LoginHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('أهلاً بيك تاني 👋', style: AppText.h(22)),
                  const SizedBox(height: 4),
                  Text('سجّل دخولك وكمّل من حيث وقفت.',
                      style: AppText.body(13, color: AppColors.neutral700)),
                  const SizedBox(height: 20),
                  LoginField(label: 'رقم الموبايل أو الإيميل', hint: '01xx xxx xxxx', controller: _id),
                  const SizedBox(height: 14),
                  LoginField(label: 'كلمة السر', hint: '••••••••', obscure: true, controller: _pass),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('نسيت كلمة السر؟', style: AppText.h(11, color: AppColors.accent)),
                  ),
                  const SizedBox(height: 18),
                  _errorText(),
                  _primaryButton(),
                  _divider(),
                  _secondary('ادخل بحساب جوجل'),
                  const SizedBox(height: 10),
                  _secondary('ادخل بحساب آبل'),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _errorText() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => p.message != c.message || p.status != c.status,
      builder: (context, s) {
        if (s.status != AuthStatus.error || s.message == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(s.message!, style: AppText.body(12, color: AppColors.danger)),
        );
      },
    );
  }

  Widget _primaryButton() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => p.isBusy != c.isBusy,
      builder: (context, s) {
        return GestureDetector(
          onTap: s.isBusy ? null : _signIn,
          child: Container(
            color: AppColors.accent,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.center,
            child: s.isBusy
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
                : Text('دخول', style: AppText.h(15, color: AppColors.white)),
          ),
        );
      },
    );
  }

  Widget _secondary(String label) {
    return GestureDetector(
      onTap: _social,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(label, style: AppText.h(14)),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(children: [
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('أو', style: AppText.kicker().copyWith(letterSpacing: 1)),
        ),
        const Expanded(child: Divider(color: AppColors.divider, height: 1)),
      ]),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('لسه مامعندكش حساب؟ ',
                style: AppText.body(12, color: AppColors.white.withValues(alpha: 0.7))),
            GestureDetector(
              onTap: context.read<AppNavCubit>().goRegister,
              child: Text('أنشئ حساب', style: AppText.h(13, color: AppColors.accent400)),
            ),
          ],
        ),
      ),
    );
  }
}
