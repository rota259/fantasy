import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/notifications/sound_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/motion.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/splash_logo.dart';

/// شاشة البداية: خلفية الهوية الفاتحة، واللوجو بيتحرّك (٢.٤ ثانية) لحد ما يبقى اللوجو والاسم جنب بعض،
/// ثم انتقال ناعم لوحده — أو ضغطة للتخطّي.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..forward();

  @override
  void initState() {
    super.initState();
    _welcomeSound();
    Future.delayed(const Duration(milliseconds: 3000), _skip);
  }

  /// نغمة الترحيب: مرة واحدة بس في عمر الأبلكيشن على الجهاز — أول مرة يتفتح بعد التنزيل
  /// (ولو الموبايل صامت مبتطلعش، وبتتحسب إنها اشتغلت).
  Future<void> _welcomeSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('welcome_sound_played') ?? false) return;
      await prefs.setBool('welcome_sound_played', true);
      await AppSounds.play(AppSounds.appStart);
    } catch (_) {}
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
    final width = MediaQuery.sizeOf(context).width;
    return Pressable(
      onTap: _skip,
      child: Scaffold(
        backgroundColor: Brand.paper,
        body: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: SplashLogo(animation: _c, size: (width * 0.24).clamp(72.0, 120.0)),
            ),
            Align(
              alignment: const Alignment(0, 0.34),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) => Opacity(opacity: ((_c.value - 0.78) / 0.2).clamp(0.0, 1.0), child: child),
                child: Text(
                  'فانتازي الحتة',
                  style: AppText.h(13, color: Brand.turf, weight: FontWeight.w600),
                ),
              ),
            ),
            Positioned(
              bottom: 46,
              child: Text('اضغط للتخطّي', style: AppText.body(11, color: Brand.ink.withValues(alpha: 0.35))),
            ),
          ],
        ),
      ),
    );
  }
}
