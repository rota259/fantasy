import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/login_header.dart';
import '../../../core/widgets/motion.dart';

/// الحساب محظور من الإدارة — مفيش دخول للأبلكيشن (والسيرفر برضه مانع أي كتابة).
class BannedScreen extends StatelessWidget {
  const BannedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const LoginHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('حسابك اتوقف 🚫', style: AppText.h(22)),
                  const SizedBox(height: 8),
                  Text(
                    'الإدارة وقفت الحساب ده. لو شايف إن ده غلط كلّم الإدارة.',
                    style: AppText.body(13, color: AppColors.neutral700),
                  ),
                  const SizedBox(height: 24),
                  Pressable(
                    onTap: context.read<AuthCubit>().signOut,
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                      padding: const EdgeInsets.all(14),
                      alignment: Alignment.center,
                      child: Text('تسجيل الخروج', style: AppText.h(15, color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
