import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../widgets/report_betting_sheet.dart';

/// «اللعب النضيف»: آية تحريم الميسر + إن الأبلكيشن للمتعة بس من غير أي فلوس، وإن أي مراهنة عليه
/// بتتحقق فيها، ولو اتثبتت = بان نهائي. بتظهر أول ما تفتح الأبلكيشن ([onAccept] = لازم يوافق)،
/// ومن «حسابي» للقراية والبلاغ.
class FairPlayScreen extends StatelessWidget {
  const FairPlayScreen({super.key, this.onAccept});

  /// موجود = أول مرة (زرار «أتعهّد»). مش موجود = فتحها من حسابي (زرار رجوع).
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            if (onAccept == null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
              ),
            Text('🚫', textAlign: TextAlign.center, style: AppText.h(54)),
            const SizedBox(height: 6),
            Text('لا للمراهنات', textAlign: TextAlign.center, style: AppText.h(24)),
            const SizedBox(height: 18),
            // الآية
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.accent100,
                borderRadius: AppRadius.lg,
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
              ),
              child: Column(
                children: [
                  Text(
                    'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: AppText.h(14, color: AppColors.accent700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '﴿ يَا أَيُّهَا الَّذِينَ آمَنُوا إِنَّمَا الْخَمْرُ وَالْمَيْسِرُ وَالْأَنصَابُ وَالْأَزْلَامُ رِجْسٌ '
                    'مِّنْ عَمَلِ الشَّيْطَانِ فَاجْتَنِبُوهُ لَعَلَّكُمْ تُفْلِحُونَ ﴾',
                    textAlign: TextAlign.center,
                    style: AppText.h(18, color: AppColors.ink, height: 1.9),
                  ),
                  const SizedBox(height: 8),
                  Text('سورة المائدة — الآية ٩٠', style: AppText.body(12, color: AppColors.accent700)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _point('⚽', 'الخماسي للمتعة والمنافسة بس — مفيش فيه أي فلوس ولا رهان، والنقط ملهاش أي قيمة مادية.'),
            _point(
              '🚫',
              'ممنوع تمامًا استخدام الأبلكيشن (التشكيلات · النقط · الدوريات · التوقعات · البطولات) في أي مراهنة.',
            ),
            _point(
              '🔍',
              'لو عرفت إن مدير منطقة أو أي حد في منطقة بيستخدم الأبلكيشن في مراهنات بلّغنا — '
                  'الإدارة هتحقق في الموضوع، ولو اتثبت هياخد بان من الأبلكيشن نهائي.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => showReportBettingSheet(context),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('بلّغ عن مراهنات'),
            ),
            if (onAccept != null) ...[
              const SizedBox(height: 10),
              FilledButton(onPressed: onAccept, child: const Text('أتعهّد إني مش هراهن — يلا نلعب')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _point(String icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: AppText.h(18)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppText.body(14, height: 1.6))),
      ],
    ),
  );
}
