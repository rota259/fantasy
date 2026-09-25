import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/notifications/notification_service.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/shell/cubit/app_nav_cubit.dart';
import 'features/shell/view/app_repositories.dart';
import 'features/shell/view/app_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شريط حالة شفّاف بأيقونات فاتحة (خلفياتنا غامقة فوق).
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light),
  );

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
        ],
        child: MaterialApp(
          title: 'الخماسي',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          builder: (context, child) => _responsiveShell(context, child!),
          home: const AppRoot(),
        ),
      ),
    );
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
