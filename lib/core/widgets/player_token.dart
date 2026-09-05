import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// توكن لاعب على أرض الملعب: تيشيرت برقم + اسم + شارة نقاط/مركز.
class PlayerToken extends StatelessWidget {
  const PlayerToken({
    super.key,
    required this.number,
    this.name,
    this.chip,
    this.isCaptain = false,
    this.chipAccent = false,
  });

  final String number;
  final String? name;
  final String? chip; // نقاط أو اسم المركز
  final bool isCaptain;
  final bool chipAccent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _jersey(),
        if (name != null) ...[
          const SizedBox(height: 3),
          Text(
            name!,
            style: AppText.h(9.5, color: AppColors.white).copyWith(
              shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 3, color: AppColors.black)],
            ),
          ),
        ],
        if (chip != null) ...[const SizedBox(height: 3), _chipBox()],
      ],
    );
  }

  Widget _jersey() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isCaptain ? AppColors.accent : AppColors.white,
            border: Border.all(color: AppColors.black, width: 2),
          ),
          child: Text(
            number,
            style: AppText.h(15, color: isCaptain ? AppColors.white : AppColors.black),
          ),
        ),
        if (isCaptain)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black, width: 2),
              ),
              child: Text('C', style: AppText.h(9, color: AppColors.accent)),
            ),
          ),
      ],
    );
  }

  Widget _chipBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      color: chipAccent ? AppColors.accent : AppColors.white,
      child: Text(
        chip!,
        style: AppText.h(9, color: chipAccent ? AppColors.white : AppColors.black),
      ),
    );
  }
}
