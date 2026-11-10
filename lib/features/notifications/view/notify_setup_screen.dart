import 'package:flutter/material.dart';

import '../../../core/notifications/device_notify.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';

part 'notify_setup_rows.dart';

/// (لكل يوزر) «الإشعارات مش بتظهر؟» — بيفحص الموبايل نفسه ويفتح الإعداد الناقص بالظبط:
///   الإذن · كل قناة (صوت + بتظهر فوق الشاشة) · التشغيل التلقائي (شاومي وأخواتها) · توفير البطارية
///   + إشعار تجربة يوصلك أنت بس (مرة كل دقيقة).
/// بيعيد الفحص لوحده لما ترجع من الإعدادات.
class NotifySetupScreen extends StatefulWidget {
  const NotifySetupScreen({super.key});

  @override
  State<NotifySetupScreen> createState() => _NotifySetupScreenState();
}

class _NotifySetupScreenState extends State<NotifySetupScreen> with WidgetsBindingObserver {
  DeviceNotifyStatus? _s;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load(); // رجع من الإعدادات
  }

  Future<void> _load() async {
    final s = await DeviceNotify.status();
    if (mounted) setState(() => _s = s);
  }

  Future<void> _test() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await SupabaseService.client.rpc('send_my_test_push');
      messenger.showSnackBar(
        const SnackBar(content: Text('اتبعت — اقفل الأبلكيشن خالص واستنى ثواني: لازم يظهر فوق الشاشة بصوت')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'الإشعارات على موبايلك', subtitle: 'NOTIFICATIONS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: s == null
                ? const SkeletonList()
                : ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    children: [
                      _summary(s),
                      ..._rows(s),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: FilledButton.icon(
                          onPressed: _sending ? null : _test,
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: Text(_sending ? 'لحظة…' : 'ابعتلي إشعار تجربة'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summary(DeviceNotifyStatus s) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: s.allGood ? AppColors.accent : AppColors.danger, borderRadius: AppRadius.md),
    child: Text(
      s.allGood
          ? 'كله تمام ✓ — الإشعارات هتظهر فوق الشاشة بصوت حتى والأبلكيشن مقفول.'
          : 'فيه حاجة على موبايلك مانعة الإشعارات أو صوتها — صلّح اللي تحت بالترتيب.',
      style: AppText.h(13, color: AppColors.white),
    ),
  );
}
