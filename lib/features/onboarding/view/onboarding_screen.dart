import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/onboard_illustrations.dart';
import '../../../core/widgets/motion.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.index});

  final int index; // 0..2

  static const _kickers = ['01 · تشكيل خماسي', '02 · بث حي', '03 · نافس واحجز'];
  static const _titles = ['كوّن فريقك الخماسي', 'تابع نقاطك لحظة بلحظة', 'نافس أصحابك واحجز ملعبك'];
  static const _bodies = [
    'اختار 5 لاعبين من ملاعب مصر بميزانية محدودة، وحطّهم على أرض على شكل خماسي حقيقي.',
    'كل جوول وتمريرة وشباك نظيفة تظهر فورًا وهي الماتشات شغّالة. مفيش انتظار.',
    'دوريات بين الشلّة، تحدّيات أسبوعية، ومزاد لاعبين — وكمان احجز ماتشك الحقيقي من نفس التطبيق.',
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _skipBar(nav),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _art(),
                    const SizedBox(height: 24),
                    Text(_kickers[index], style: AppText.kicker(color: AppColors.accent)),
                    const SizedBox(height: 8),
                    Text(_titles[index], style: AppText.h(30, height: 1.15)),
                    const SizedBox(height: 8),
                    Text(_bodies[index], style: AppText.body(14, color: AppColors.neutral700)),
                  ],
                ),
              ),
            ),
          ),
          _footer(nav),
        ],
      ),
    );
  }

  Widget _art() {
    switch (index) {
      case 0:
        return const OnboardPitchArt();
      case 1:
        return const OnboardFeedArt();
      default:
        return const OnboardTrophyArt();
    }
  }

  Widget _skipBar(AppNavCubit nav) {
    return Container(
      color: AppColors.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
          child: Row(
            children: [
              const Spacer(),
              Pressable(
                onTap: nav.onboardSkip,
                child: Text('تخطّي ✕', style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(AppNavCubit nav) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 34),
      child: Column(
        children: [
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(left: i == 2 ? 0 : 6),
                  color: i == index ? AppColors.accent : AppColors.neutral300,
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: nav.onboardNext,
            child: Container(
              width: double.infinity,
              color: AppColors.accent,
              padding: const EdgeInsets.all(14),
              alignment: Alignment.center,
              child: Text(index >= 2 ? 'يلا نبدأ' : 'التالي', style: AppText.h(15, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
