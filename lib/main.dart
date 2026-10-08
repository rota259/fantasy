import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/app_navigator.dart';
import 'core/notifications/notification_service.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_cubit.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/shell/cubit/app_nav_cubit.dart';
import 'features/shell/view/app_repositories.dart';
import 'features/shell/view/app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase فقط لو المفاتيح ممرّرة بـ --dart-define.
  if (SupabaseConfig.isConfigured) {
    await SupabaseService.init();
  }

  await NotificationService.init();

  runApp(const FantasyApp());
}

class FantasyApp extends StatelessWidget {
  const FantasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // الـ repositories والـ cubits العامة (المصادقة + التنقّل) فوق الـ MaterialApp
    // عشان أي شاشة بتتفتح بـ push تقدر توصلهم.
    return AppRepositories(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppNavCubit()),
          BlocProvider(create: (c) => AuthCubit(c.read<AuthRepository>())..checkSession()),
          BlocProvider(create: (_) => ThemeModeCubit()),
        ],
        child: BlocBuilder<ThemeModeCubit, ThemeMode>(
          builder: (context, mode) => MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'الخماسي',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: AppTheme.of(AppPalette.light),
            darkTheme: AppTheme.of(AppPalette.dark),
            themeAnimationDuration: const Duration(milliseconds: 250),
            builder: (context, child) => _themed(context, child!),
            home: const AppRoot(),
          ),
        ),
      ),
    );
  }

  /// الوضع (فاتح/داكن) بيتطبّق على ألوان الشاشات قبل ما تتبني — وتغييره بيبنيها من جديد.
  /// + شريط "STAGING" عشان محدش يخلط بين مشروع التجربة والأصلي.
  Widget _themed(BuildContext context, Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    AppColors.use(dark ? AppPalette.dark : AppPalette.light);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // فوق الترويسة الغامقة في الوضعين
        systemNavigationBarColor: AppColors.bg,
        systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      ),
    );
    final shell = KeyedSubtree(key: ValueKey(dark), child: _responsiveShell(context, child));
    return SupabaseConfig.isStaging
        ? Banner(message: 'STAGING', location: BannerLocation.topStart, child: shell)
        : shell;
  }

  /// يجعل التطبيق responsive:
  /// - النص/الأحجام تتناسب مع عرض الجهاز (التصميم معمول على 390px).
  /// - RTL للعربية.
  /// - على الشاشات العريضة (تابلت) يتوسّط في عمود بعرض موبايل.
  Widget _responsiveShell(BuildContext context, Widget child) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    // معامل التحجيم بالنسبة لعرض التصميم (390) مع حدود آمنة.
    final scale = (width / 390).clamp(0.85, 1.15);

    final scaled = MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(textDirection: TextDirection.rtl, child: child),
    );

    // على الموبايل (عرض < 640) مفيش أثر؛ على الأعرض نتوسّط.
    return ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: scaled),
      ),
    );
  }
}
