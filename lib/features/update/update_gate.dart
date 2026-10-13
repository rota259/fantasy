import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/supabase/supabase_config.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/launchers.dart';
import '../../core/widgets/brand_logo.dart';

/// رقم نسخة الأبلكيشن اللي شغّالة (الرقم اللي بعد + في pubspec: version 1.0.0+N) والمنصّة.
abstract final class AppBuild {
  static Future<int> number() async {
    try {
      return int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static bool get isIos => !kIsWeb && Platform.isIOS;
  static String get platform => isIos ? 'ios' : 'android';
}

/// التحديث الإجباري: أول ما الأبلكيشن يفتح (وكل ما يرجع من الخلفية) بيسأل السيرفر عن أقل نسخة مسموحة.
/// لو نسخة الجهاز أقدم → شاشة «حدّث الأبلكيشن» بتقفل كل حاجة لحد ما يتحدّث.
/// لو النت واقع أو السيرفر مردّش → الأبلكيشن بيفتح عادي (منقفلش الناس بسبب عطل).
class UpdateGate extends StatefulWidget {
  const UpdateGate({super.key, required this.child});
  final Widget child;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> with WidgetsBindingObserver {
  ({String message, String store})? _blocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _check() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final cfg = Map<String, dynamic>.from(await SupabaseService.client.rpc('get_app_config') as Map);
      final min = int.tryParse('${cfg['min_build_${AppBuild.platform}'] ?? 0}') ?? 0;
      final mine = await AppBuild.number();
      if (!mounted) return;
      setState(() {
        _blocked = mine > 0 && mine < min
            ? (
                message: (cfg['update_message'] as String?)?.trim().isNotEmpty == true
                    ? cfg['update_message'] as String
                    : 'فيه نسخة جديدة من الخماسي — حدّث عشان تكمّل',
                store: (cfg['store_${AppBuild.platform}'] as String?) ?? '',
              )
            : null;
      });
    } catch (_) {} // منقفلش الأبلكيشن بسبب عطل في النت
  }

  @override
  Widget build(BuildContext context) {
    final b = _blocked;
    return Stack(
      children: [
        widget.child,
        if (b != null)
          Positioned.fill(
            child: _UpdateScreen(message: b.message, store: b.store, onRetry: _check),
          ),
      ],
    );
  }
}

class _UpdateScreen extends StatelessWidget {
  const _UpdateScreen({required this.message, required this.store, required this.onRetry});
  final String message, store;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // زرار الرجوع مبيعدّيش الشاشة
      child: Scaffold(
        backgroundColor: Brand.paper,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandLockup(height: 64)),
                const SizedBox(height: 36),
                Icon(Icons.system_update_alt_rounded, size: 46, color: Brand.turf),
                const SizedBox(height: 14),
                Text(
                  'محتاج تحدّث الأبلكيشن',
                  textAlign: TextAlign.center,
                  style: AppText.h(22, color: Brand.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.body(14, color: Brand.ink.withValues(alpha: 0.7), height: 1.7),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Brand.turf, padding: const EdgeInsets.all(14)),
                  onPressed: store.isEmpty ? null : () => Launchers.url(store),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('حدّث دلوقتي'),
                ),
                TextButton(onPressed: onRetry, child: const Text('حدّثت خلاص — جرّب تاني')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
