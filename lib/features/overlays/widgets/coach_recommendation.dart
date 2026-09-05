import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../coach/coach_engine.dart';

/// بطاقة توصية التحويل (يخرج/يدخل + شريط ثقة + زرّين).
class CoachRecommendation extends StatelessWidget {
  const CoachRecommendation({super.key, required this.onAct, this.advice});

  final VoidCallback onAct;
  final CoachAdvice? advice;

  @override
  Widget build(BuildContext context) {
    final a = advice;
    final outName = a != null ? '${a.out.name} ✕' : 'زياد ✕';
    final outMeta = a != null ? 'فورمة ${a.out.form.toStringAsFixed(1)} · ${a.out.price.toStringAsFixed(1)}م' : 'فورمة 2.1 · 4.8م';
    final inName = a != null ? '${a.incoming.name} ✓' : 'طارق ✓';
    final inMeta = a != null ? 'فورمة ${a.incoming.form.toStringAsFixed(1)} · ${a.incoming.price.toStringAsFixed(1)}م' : 'فورمة 8.6 · 5.2م';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _side('يخرج · OUT', outName, outMeta,
                    bg: AppColors.neutral100, kickerColor: AppColors.neutral600, rightBorder: true),
                _side('يدخل · IN', inName, inMeta,
                    bg: AppColors.accent100, kickerColor: AppColors.accent700),
              ],
            ),
          ),
          _body(a),
          _buttons(),
        ],
      ),
    );
  }

  Widget _side(String k, String name, String meta,
      {required Color bg, required Color kickerColor, bool rightBorder = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bg,
          border: rightBorder
              ? const Border(left: BorderSide(color: AppColors.black, width: 2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: AppText.kicker(color: kickerColor)),
            const SizedBox(height: 3),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.h(15)),
            Text(meta, style: AppText.body(10, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }

  Widget _body(CoachAdvice? a) {
    final gain = a != null ? '+${a.expectedGain} نقاط' : '+6 نقاط';
    final conf = a?.confidence ?? 82;
    final lead = a != null
        ? '${a.incoming.name} فورمته أعلى ومتوقّع '
        : 'طارق عليه 3 ماتشات سهلة وبيسجّل بانتظام. متوقّع ';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.black, width: 2))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: lead, style: AppText.body(12, color: AppColors.neutral700)),
            TextSpan(text: gain, style: AppText.h(12, color: AppColors.accent700)),
            TextSpan(text: '.', style: AppText.body(12, color: AppColors.neutral700)),
          ])),
          const SizedBox(height: 10),
          Row(children: [
            Text('ثقة', style: AppText.kicker()),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 6,
                color: AppColors.neutral300,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: conf / 100,
                    child: Container(color: AppColors.accent),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$conf%', style: AppText.h(12)),
          ]),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.black, width: 2))),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: onAct,
              child: Container(
                padding: const EdgeInsets.all(9),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  border: Border(left: BorderSide(color: AppColors.black, width: 2)),
                ),
                child: Text('نفّذ التحويل', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onAct,
              child: Container(
                padding: const EdgeInsets.all(9),
                alignment: Alignment.center,
                child: Text('تجاهل', style: AppText.h(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
