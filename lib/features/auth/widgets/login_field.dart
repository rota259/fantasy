import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// حقل إدخال بستايل الديزاين: كيكر + مربّع بحد أسود 2px، صفر انحناء.
class LoginField extends StatelessWidget {
  const LoginField({super.key, required this.label, required this.hint, this.obscure = false, this.controller});

  final String label;
  final String hint;
  final bool obscure;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.kicker()),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: AppText.h(14),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: AppText.h(14, color: AppColors.neutral500),
            ),
          ),
        ),
      ],
    );
  }
}
