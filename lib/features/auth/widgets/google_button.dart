import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/google_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../cubit/auth_cubit.dart';
import '../../../core/widgets/motion.dart';

/// "أو" + زرار الدخول بجوجل — بيختفي لو مفتاح جوجل مش متحدّد (GoogleAuth.webClientId).
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!GoogleAuth.isEnabled) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider, height: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('أو', style: AppText.kicker().copyWith(letterSpacing: 1)),
              ),
              Expanded(child: Divider(color: AppColors.divider, height: 1)),
            ],
          ),
        ),
        BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (p, c) => p.isBusy != c.isBusy,
          builder: (context, s) => Pressable(
            onTap: s.isBusy ? null : context.read<AuthCubit>().signInWithGoogle,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('G', style: AppText.h(18, color: AppColors.info)),
                  const SizedBox(width: 10),
                  Text('ادخل بحساب جوجل', style: AppText.h(14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
