import 'package:fantasy_5omasi/cubits/auth/auth_cubit.dart';
import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback onPressed;
  const AuthButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;

    if (state is AuthLoading) {
      return const CircularProgressIndicator();
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85, // أقل من عرض الشاشة بـ 15%
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen, // لون الخلفية من الثيم
          foregroundColor: Colors.white, // لون النص
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3, // ظل خفيف للزر
        ),
onPressed: () async {
  onPressed(); // ينفذ لوجيك تسجيل الدخول
  final state = context.read<AuthCubit>().state;
  if (state is AuthSuccess) {
    Navigator.pushReplacementNamed(context, '/home');
  }
},        child: const Text(
          'دخول',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
