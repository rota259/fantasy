import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// منطقة شريط الحالة (فوق الـ notch). بترسم خلفية ملوّنة تحت ساعة الـ OS،
/// وممكن تحمل زر/أكشن على الجنب (زي "تخطّي" في الـ onboarding).
class StatusArea extends StatelessWidget {
  const StatusArea({super.key, this.color, this.trailing});

  final Color? color; // الافتراضي accent (نفس لون الترويسة الخضرا)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color ?? AppColors.accent,
      child: SafeArea(
        bottom: false,
        child: trailing == null
            ? const SizedBox(height: 6)
            : Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 6),
                child: Row(children: [const Spacer(), trailing!]),
              ),
      ),
    );
  }
}
