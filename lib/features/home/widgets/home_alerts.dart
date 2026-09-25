import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// تنبيه في الهوم (قيّم ماتش / صوّت في تعادل تشكيلة الجولة ...).
typedef HomeAlert = ({String text, Color color, VoidCallback onTap});

/// شرايط التنبيهات تحت النقط — بتختفي لو مفيش حاجة.
class HomeAlerts extends StatelessWidget {
  const HomeAlerts({super.key, required this.alerts});

  final List<HomeAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final a in alerts)
          GestureDetector(
            onTap: a.onTap,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: a.color,
              child: Row(
                children: [
                  Expanded(
                    child: Text(a.text, style: AppText.h(12, color: AppColors.white)),
                  ),
                  Text('›', style: AppText.h(16, color: AppColors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
