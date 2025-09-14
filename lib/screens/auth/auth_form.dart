import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fantasy_5omasi/cubits/auth/auth_cubit.dart';
import 'package:fantasy_5omasi/screens/auth/auth_button.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final topSpacing = MediaQuery.of(context).size.height * 0.125;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          final role = state.user.role;
          final isActive = state.user.isActive;

          if (!isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("الحساب غير مفعل")),
            );
            return;
          }

          if (role == 'manager') {
            Navigator.pushReplacementNamed(context, '/managerHub');
          } else if (role == 'user') {
            Navigator.pushReplacementNamed(context, '/userHub');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("نوع الحساب غير معروف")),
            );
          }
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            SizedBox(height: topSpacing),
            const Text(
              "تسجيل الدخول",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // البريد أو الموبايل
            Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                controller: emailController,
                decoration: _inputDecoration('البريد الإلكتروني أو رقم الموبايل'),
              ),
            ),

            // كلمة المرور
            Container(
              margin: const EdgeInsets.only(bottom: 20),
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
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration('كلمة المرور'),
              ),
            ),

            // زر الدخول
            AuthButton(
              onPressed: () {
                context.read<AuthCubit>().signIn(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
              },
            ),

            if (state is AuthLoading) const SizedBox(height: 20),
            if (state is AuthLoading) const CircularProgressIndicator(),
          ],
        );
      },
    );
  }
}
