import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/login_field.dart';
import '../widgets/login_header.dart';

/// شاشة إنشاء حساب جديد — موصولة بـ AuthCubit.signUp.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _ref = TextEditingController(); // كود دعوة (اختياري)

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _ref.dispose();
    super.dispose();
  }

  void _register() {
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signUp(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      password: _pass.text,
      referralCode: _ref.text,
    );
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
                  Text('اعمل حسابك 🚀', style: AppText.h(22)),
                  const SizedBox(height: 4),
                  Text('كوّن فريقك ونافس أصحابك.', style: AppText.body(13, color: AppColors.neutral700)),
                  const SizedBox(height: 20),
                  LoginField(label: 'الاسم', hint: 'محمد كمال', controller: _name),
                  const SizedBox(height: 14),
                  LoginField(label: 'الإيميل', hint: 'you@email.com', controller: _email),
                  const SizedBox(height: 14),
                  LoginField(label: 'رقم الموبايل', hint: '01xx xxx xxxx', controller: _phone),
                  const SizedBox(height: 14),
                  LoginField(label: 'كلمة السر', hint: '••••••••', obscure: true, controller: _pass),
                  const SizedBox(height: 14),
                  LoginField(label: 'كود دعوة صاحبك (اختياري)', hint: 'ABC123', controller: _ref),
                  const SizedBox(height: 18),
                  _errorText(),
                  _button(),
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

  Widget _button() {
    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (p, c) => p.isBusy != c.isBusy,
      builder: (context, s) => GestureDetector(
        onTap: s.isBusy ? null : _register,
        child: Container(
          color: AppColors.accent,
          padding: const EdgeInsets.all(14),
          alignment: Alignment.center,
          child: s.isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                )
              : Text('أنشئ حساب', style: AppText.h(15, color: AppColors.white)),
        ),
      ),
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
            Text('عندك حساب بالفعل؟ ', style: AppText.body(12, color: AppColors.white.withValues(alpha: 0.7))),
            GestureDetector(
              onTap: context.read<AppNavCubit>().goLogin,
              child: Text('سجّل دخول', style: AppText.h(13, color: AppColors.accent400)),
            ),
          ],
        ),
      ),
    );
  }
}
