import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pill.dart';

/// بطاقة المواجهة القابلة للمشاركة (أنت ضد الخصم).
class ChallengeVsCard extends StatelessWidget {
  const ChallengeVsCard({
    super.key,
    required this.meName,
    required this.meScore,
    required this.oppName,
    required this.oppScore,
    required this.meWins,
  });

  final String meName;
  final String meScore;
  final String oppName;
  final String oppScore;
  final bool meWins;

  String _ini(String n) => n.trim().length >= 2 ? n.trim().substring(0, 2) : n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.accent,
        border: Border.all(color: AppColors.black, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x59FFFFFF), width: 2)),
            ),
            child: Text(
              'الخماسي · تحدّي الجولة 07',
              textAlign: TextAlign.center,
              style: AppText.h(10, color: AppColors.white, spacingEm: 0.18),
            ),
          ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _side(_ini(meName), meName, meScore, winner: meWins),
                Container(width: 2, color: const Color(0x59FFFFFF)),
                _side(_ini(oppName), oppName, oppScore, winner: !meWins),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _side(String ini, String name, String score, {required bool winner}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              color: winner ? AppColors.white : AppColors.black,
              child: Text(ini,
                  style: AppText.h(15, color: winner ? AppColors.black : AppColors.white)),
            ),
            const SizedBox(height: 8),
            Text(name, style: AppText.h(14, color: AppColors.white)),
            const SizedBox(height: 4),
            Opacity(
              opacity: winner ? 1 : 0.8,
              child: Text(score, style: AppText.h(52, color: AppColors.white, height: 0.9)),
            ),
            const SizedBox(height: 6),
            if (winner)
              const Pill('فائز 🏆', background: AppColors.black, color: AppColors.white)
            else
              const SizedBox(height: 23),
          ],
        ),
      ),
    );
  }
}
