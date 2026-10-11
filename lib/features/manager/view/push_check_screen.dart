import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../squad/data/profile_repository.dart';
import '../../../core/notifications/notification_service.dart';
import '../data/admin_repository.dart';

/// (أدمن) فحص إشعارات الموبايل: ليه الإشعار مبيوصلش والأبلكيشن مقفول؟
/// خمس حاجات لازم يبقوا ✓ — وكل واحدة ناقصة مكتوب جنبها تتصلّح إزاي — وزرار إشعار تجربة.
class PushCheckScreen extends StatefulWidget {
  const PushCheckScreen({super.key});

  @override
  State<PushCheckScreen> createState() => _PushCheckScreenState();
}

class _PushCheckScreenState extends State<PushCheckScreen> {
  late final AdminRepository _repo = context.read<AdminRepository>();
  Map<String, dynamic>? _d;
  bool? _allowed; // إذن الإشعارات على الجهاز ده
  String? _error;
  bool _busy = false;

  String get _expectedUrl => '${SupabaseConfig.url}/functions/v1/push';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      _allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (_) {
      _allowed = false;
    }
    try {
      final d = await _repo.pushDiagnostics();
      if (mounted) {
        setState(() {
          _d = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = dbMessage(e, fallback: 'شغّل ملف الداتابيز (قسم 46) وجرّب تاني'));
    }
  }

  Future<void> _do(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _askPermission() => _do(() async {
    await FirebaseMessaging.instance.requestPermission();
  }, 'لو مظهرش سؤال الإذن: افتح إعدادات الموبايل ← التطبيقات ← الخماسي ← الإشعارات وفعّلها');

  Future<void> _registerToken() => _do(() async {
    final u = context.read<AuthCubit>().state.user;
    if (u != null) await NotificationService.registerToken(u.id, context.read<ProfileRepository>());
  }, 'اتسجّل الجهاز ✓');

  Future<void> _test() => _do(() async {
    await _repo.sendTestPush();
    await Future<void>.delayed(const Duration(seconds: 5)); // الفانكشن بترد خلال ثواني
  }, 'اتبعت — اقفل الأبلكيشن وشوف وصل ولا لأ. الرد ظاهر تحت في «آخر محاولات»');

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'فحص الإشعارات', subtitle: 'ADMIN · PUSH', onBack: () => Navigator.pop(context)),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppText.body(13, color: AppColors.danger),
                      ),
                    ),
                  )
                : d == null
                ? const SkeletonList()
                : RefreshIndicator(onRefresh: _load, child: _body(d)),
          ),
        ],
      ),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final url = d['push_url'] as String?;
    final last = ((d['last'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final lastOk = last.isNotEmpty && last.first['status'] == 200;
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            'عشان الإشعار يوصل ويعمل صوت والأبلكيشن مقفول، الخمسة دول لازم يبقوا ✓',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
        ),
        _check(
          'إذن الإشعارات على الموبايل ده',
          _allowed == true,
          fix: 'الموبايل مانع الإشعارات عن الأبلكيشن',
          action: ('اطلب الإذن', _askPermission),
        ),
        _check(
          'الجهاز ده متسجّل (${d['tokens'] ?? 0} جهاز متسجّل في الكل)',
          d['my_token'] == true,
          fix: 'الأبلكيشن مسجّلش الجهاز — غالبًا النت كان واقع وقت الدخول',
          action: ('سجّل الجهاز', _registerToken),
        ),
        _check(
          'إضافة pg_net في الداتابيز',
          d['pg_net'] == true,
          fix: 'من لوحة Supabase: Database ← Extensions ← فعّل pg_net ← وشغّل ملف الداتابيز تاني',
        ),
        _check(
          'رابط فانكشن الإشعارات',
          url == _expectedUrl,
          fix: url == null ? 'الداتابيز متعرفش تبعت لمين — دوس الزرار' : 'الرابط المتسجّل لمشروع تاني:\n$url',
          action: ('ظبّط الرابط', () => _do(() => _repo.setPushUrl(_expectedUrl), 'الرابط اتظبط ✓')),
        ),
        _check(
          'الفانكشن بترد صح',
          lastOk,
          fix: last.isEmpty ? 'مفيش محاولات لسه — ابعت إشعار تجربة' : _explain(last.first),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: FilledButton.icon(
            onPressed: _busy ? null : _test,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(_busy ? 'لحظة…' : 'ابعتلي إشعار تجربة'),
          ),
        ),
        if (last.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('آخر محاولات', style: AppText.kicker(color: AppColors.accent)),
          ),
          for (final r in last)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Text(
                '${r['status'] ?? '—'} · ${r['error'] ?? r['body'] ?? ''}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.ltr,
                style: AppText.body(11, color: r['status'] == 200 ? AppColors.neutral700 : AppColors.danger),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'لو الخمسة ✓ ولسه مبيوصلش والأبلكيشن مقفول: موبايلات شاومي وأوبو وريلمي وهواوي بتقفل الأبلكيشنز في الخلفية — '
            'من إعدادات الموبايل افتح الأبلكيشن وفعّل «التشغيل التلقائي» وشيل «توفير البطارية» عنه.',
            style: AppText.body(11, color: AppColors.neutral600, height: 1.6),
          ),
        ),
      ],
    );
  }

  /// رد الفانكشن الغلط معناه إيه.
  static String _explain(Map<String, dynamic> r) {
    final status = r['status'];
    final text = '${r['error'] ?? ''} ${r['body'] ?? ''}'.toLowerCase();
    if (status == 404) {
      return 'الفانكشن مش منشورة على المشروع ده — انشرها:\nnpx supabase functions deploy push --no-verify-jwt';
    }
    if (status == 401) return 'الفانكشن اتنشرت من غير --no-verify-jwt — انشرها تاني بيها';
    if (status == 403) return 'السر مش متطابق — شغّل ملف الداتابيز تاني';
    if (text.contains('fcm auth') || text.contains('private_key') || status == 500) {
      return 'سر Firebase ناقص أو غلط — حط FIREBASE_SERVICE_ACCOUNT في أسرار الفانكشن وانشرها تاني';
    }
    if (status == null) return 'الطلب ماوصلش للفانكشن: ${r['error'] ?? 'اتأكد من الرابط'}';
    return 'الفانكشن ردّت بـ $status';
  }

  Widget _check(String title, bool ok, {required String fix, (String, Future<void> Function())? action}) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.all(12),
    decoration: AppDecor.tile,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? AppColors.accent : AppColors.danger, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h(13)),
              if (!ok) ...[
                const SizedBox(height: 2),
                Text(fix, style: AppText.body(11, color: AppColors.neutral700, height: 1.5)),
                if (action != null)
                  TextButton(
                    onPressed: _busy ? null : action.$2,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    child: Text(action.$1),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
