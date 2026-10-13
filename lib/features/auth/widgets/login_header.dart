import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/brand_logo.dart';

/// ترويسة الدخول السوداء: لوجو الصديري + الاسم بخط الهوية.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 30),
          child: Row(
            children: [
              const BibLogo.onDark(size: 60),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandWordmark(size: 40, color: Colors.white),
                    const SizedBox(height: 3),
                    Text(
                      'فانتازي الغلابه',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h(11, color: AppColors.accent400, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
