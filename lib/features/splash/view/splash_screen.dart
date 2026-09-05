import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/splash_logo.dart';

/// شاشة البداية: لوجو متحرّك ثم انتقال تلقائي بعد 2.8 ثانية، أو ضغطة للتخطّي.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
        ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 4800), _skip);
  }

  void _skip() {
    if (mounted) context.read<AppNavCubit>().goOnboard();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _skip,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          alignment: Alignment.center,
          children: [
            // اللوجو في نص الشاشة بالظبط
            Center(child: SplashLogo(animation: _c, size: 240)),
            // الاسم تحت المنتصف
            Align(
              alignment: const Alignment(0, 0.42),
              child: _wordmark(),
            ),
            Positioned(bottom: 70, child: _loadingBar()),
            Positioned(
              bottom: 46,
              child: Text(
                'اضغط للتخطّي',
                style: AppText.h(9, weight: FontWeight.w600, spacingEm: 0.2)
                    .copyWith(color: AppColors.white.withValues(alpha: 0.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wordmark() {
    final fade = ((_c.value - 0.6) / 0.4).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Opacity(
        opacity: fade,
        child: Column(
          children: [
            Text('الخماسي', style: AppText.h(34, color: AppColors.white, spacingEm: -0.02)),
            const SizedBox(height: 6),
            Text(
              'FANTASY · FIVE-A-SIDE',
              style: AppText.h(9, color: AppColors.neutral400, weight: FontWeight.w600, spacingEm: 0.34),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingBar() {
    return Container(
      width: 120,
      height: 3,
      color: AppColors.white.withValues(alpha: 0.15),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Align(
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: _c.value,
            child: Container(color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}
