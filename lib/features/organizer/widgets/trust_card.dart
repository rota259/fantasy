import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// مصداقية المدير: ماتشات معتمدة/ملغية + الإنذارات. الجديد ماتشاته محتاجة تأكيد الخصم أو الأدمن.
class TrustCard extends StatelessWidget {
  const TrustCard({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: SupabaseService.client.rpc('organizer_trust', params: {'p_user': userId}),
    builder: (context, snap) {
      final m = snap.data is Map ? snap.data as Map : null;
      if (m == null) return const SizedBox.shrink();
      final ok = (m['approved'] as num?)?.toInt() ?? 0;
      final bad = (m['voided'] as num?)?.toInt() ?? 0;
      final strikes = (m['strikes'] as num?)?.toInt() ?? 0;
      final trusted = m['trusted'] == true;
      final score = (m['score'] as num?)?.toInt();
      final color = strikes > 0 ? AppColors.danger : (trusted ? AppColors.accent : AppColors.gold);
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: color, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trusted ? Icons.verified_outlined : Icons.hourglass_top, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('مصداقيتك ${score == null ? '' : '$score٪'}', style: AppText.h(15))),
                Text('إنذارات $strikes/3', style: AppText.h(12, color: color)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              trusted
                  ? '$ok ماتش معتمد · $bad ملغي — ماتشاتك بتتعتمد لوحدها بعد ٤ ساعات لو محدش اعترض'
                  : 'مدير جديد ($ok/5 معتمد) — ماتشك بيتعتمد بتأكيد كابتن الخصم أو الإدارة',
              style: AppText.body(12, color: AppColors.neutral700),
            ),
          ],
        ),
      );
    },
  );
}
