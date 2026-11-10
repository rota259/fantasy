import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../zones/data/zone.dart';
import '../../zones/widgets/zone_field.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/google_button.dart';
import '../widgets/login_field.dart';
import '../widgets/login_header.dart';
import '../../../core/widgets/motion.dart';

part 'register_screen_sections.dart';

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
  Zone? _zone;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _ref.dispose();
    super.dispose();
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
                  Text('اعمل حسابك', style: AppText.h(22)),
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
                  ZoneField(value: _zone, onChanged: (z) => setState(() => _zone = z)),
                  const SizedBox(height: 14),
                  LoginField(label: 'كود دعوة صاحبك (اختياري)', hint: 'ABC123', controller: _ref),
                  const SizedBox(height: 18),
                  _errorText(),
                  _button(),
                  const GoogleButton(),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }
}
