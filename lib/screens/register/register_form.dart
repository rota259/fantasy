import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fantasy_5omasi/cubits/regestire/regestire_cubit.dart';
import 'package:fantasy_5omasi/cubits/regestire/regestire_state.dart';
import 'package:fantasy_5omasi/screens/auth/auth_button.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String selectedRole = 'user'; // default

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 16),
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "اختر نوع الحساب:",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Radio<String>(
              value: 'user',
              groupValue: selectedRole,
              onChanged: (value) => setState(() => selectedRole = value!),
            ),
            const Text("لاعب عادي"),
            Radio<String>(
              value: 'manager',
              groupValue: selectedRole,
              onChanged: (value) => setState(() => selectedRole = value!),
            ),
            const Text("مدير فريق"),
          ],
        ),
      ],
    );
  }

  void _submitRegistration(BuildContext context) {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى ملء جميع الحقول")),
      );
      return;
    }

    context.read<RegisterCubit>().registerUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: selectedRole,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topSpacing = MediaQuery.of(context).size.height * 0.125;

    return BlocConsumer<RegisterCubit, RegisterState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تم إنشاء الحساب بنجاح!")),
          );
          Navigator.pushReplacementNamed(context, '/auth');
        } else if (state is RegisterFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: topSpacing),
            const Text(
              "إنشاء حساب جديد",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildField(controller: nameController, label: 'الاسم'),
            _buildField(controller: emailController, label: 'البريد الإلكتروني'),
            _buildField(controller: phoneController, label: 'رقم الموبايل'),
            _buildField(
              controller: passwordController,
              label: 'كلمة المرور',
              obscure: true,
              margin: const EdgeInsets.only(bottom: 24),
            ),
            _buildRoleSelector(),
            const SizedBox(height: 16),
            AuthButton(onPressed: () => _submitRegistration(context)),
            if (state is RegisterLoading) const SizedBox(height: 20),
            if (state is RegisterLoading) const CircularProgressIndicator(),
          ],
        );
      },
    );
  }
}
