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
import '../../notifications/view/notify_setup_screen.dart';
import '../data/admin_repository.dart';

part 'push_check_screen_sections.dart';
part 'push_check_screen_sections2.dart';

/// (أدمن) فحص إشعارات الموبايل: ليه الإشعار مبيوصلش والأبلكيشن مقفول؟
/// خمس حاجات لازم يبقوا ✓ — وكل واحدة ناقصة مكتوب جنبها تتصلّح إزاي — وزرار إشعار تجربة.
class PushCheckScreen extends StatefulWidget {
  const PushCheckScreen({super.key});

  @override
  State<PushCheckScreen> createState() => _PushCheckScreenState();
}

class _PushCheckScreenState extends State<PushCheckScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

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

  /// الفانكشن ردت ٢٠٠ بس Firebase رفض الإرسال (ok:false · أو اتبعت لصفر جهاز من كذا).
  static bool _fcmFailed(Map<String, dynamic> r) {
    final body = '${r['body'] ?? ''}'.replaceAll(' ', '');
    return body.contains('"ok":false') || RegExp(r'"sent":0,"total":[1-9]').hasMatch(body);
  }

  /// رد الفانكشن الغلط معناه إيه.
  static String _explain(Map<String, dynamic> r) {
    final status = r['status'];
    final text = '${r['error'] ?? ''} ${r['body'] ?? ''}'.toLowerCase();
    if (status == 200 && _fcmFailed(r)) {
      return 'الفانكشن شغّالة بس Firebase رفض الإرسال — غالبًا سر FIREBASE_SERVICE_ACCOUNT لمشروع Firebase تاني '
          'غير اللي في google-services.json، أو توكن الجهاز قديم (دوس «سجّل الجهاز»).';
    }
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
}
