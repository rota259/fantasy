import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'rasp.dart';

/// لو الحماية كشفت محاولة اختراق وهي شغّالة: الأبلكيشن بيتقفل بشاشة واحدة بدل أي حاجة تانية.
class RaspGate extends StatelessWidget {
  const RaspGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String?>(
    valueListenable: Rasp.blocked,
    builder: (context, threat, _) => threat == null
        ? child
        : Material(
            color: AppColors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gpp_bad_outlined, size: 64, color: AppColors.danger),
                    const SizedBox(height: 16),
                    Text('الأبلكيشن اتقفل لحمايتك', style: AppText.h(18, color: AppColors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'اكتشفنا أداة بتحاول تتحكّم في الأبلكيشن وهو شغّال. اقفل أي برامج تعديل أو تصحيح ونزّل الأبلكيشن من جوجل بلاي.',
                      textAlign: TextAlign.center,
                      style: AppText.body(13, color: AppColors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );
}
