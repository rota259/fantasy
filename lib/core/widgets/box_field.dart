import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

/// حقل كتابة بإطار أسود 2px (الستايل الموحّد للفورمز).
class BoxField extends StatelessWidget {
  const BoxField({super.key, required this.controller, required this.hint, this.keyboard, this.maxLines = 1});

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: AppText.h(14),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            hintText: hint,
          ),
        ),
      ),
    );
  }
}

/// عنوان قسم أخضر صغير في الفورم.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: AppText.kicker(color: AppColors.accent)),
  );
}
