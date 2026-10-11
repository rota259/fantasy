import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';

/// تنبيه في الهوم (قيّم ماتش / صوّت في تعادل تشكيلة الجولة ...).
typedef HomeAlert = ({IconData icon, String text, Color color, VoidCallback onTap});

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
          Pressable(
            onTap: a.onTap,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: a.color, borderRadius: AppRadius.md),
              child: Row(
                children: [
                  Icon(a.icon, size: 18, color: AppColors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.text, style: AppText.h(12, color: AppColors.white)),
                  ),
                  Icon(Icons.chevron_left, size: 18, color: AppColors.white.withValues(alpha: 0.8)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
