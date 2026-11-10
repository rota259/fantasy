import 'package:flutter/material.dart';

import '../../core/supabase/db_error.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/fx/skeleton.dart';
import '../../core/widgets/masthead.dart';
import '../../core/widgets/status_bar.dart';
import 'update_gate.dart';

part 'admin_update_screen_sections.dart';

/// (أدمن) التحديث الإجباري: أقل رقم نسخة مسموح لأندرويد وآيفون + لينكات المتجر + الرسالة.
/// أي جهاز نسخته أقدم من الرقم ده الأبلكيشن مبيفتحش عنده غير لما يحدّث.
class AdminUpdateScreen extends StatefulWidget {
  const AdminUpdateScreen({super.key});

  @override
  State<AdminUpdateScreen> createState() => _AdminUpdateScreenState();
}

class _AdminUpdateScreenState extends State<AdminUpdateScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  final _minAndroid = TextEditingController();
  final _minIos = TextEditingController();
  final _storeAndroid = TextEditingController();
  final _storeIos = TextEditingController();
  final _message = TextEditingController();
  int _mine = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_minAndroid, _minIos, _storeAndroid, _storeIos, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'التحديث الإجباري', subtitle: 'ADMIN · FORCE UPDATE', onBack: () => Navigator.pop(context)),
          Expanded(
            child: _loading
                ? const SkeletonList()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
                        child: Text(
                          'نسخة موبايلك دلوقتي: $_mine (${AppBuild.isIos ? 'آيفون' : 'أندرويد'}).\n'
                          'رقم النسخة هو الرقم اللي بعد علامة + في pubspec.yaml (مثلًا 1.0.0+7 ← 7). '
                          'أي جهاز رقمه أقل من «أقل نسخة» الأبلكيشن مبيفتحش عنده غير لما يحدّث. سيب الرقم 0 = مفيش إجبار.',
                          style: AppText.body(12, color: AppColors.accent700, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(_minAndroid, 'أقل نسخة — أندرويد', number: true),
                      _field(_storeAndroid, 'لينك Google Play'),
                      _field(_minIos, 'أقل نسخة — آيفون', number: true),
                      _field(_storeIos, 'لينك App Store'),
                      _field(_message, 'الرسالة اللي بتظهر لليوزر', lines: 2),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => (AppBuild.isIos ? _minIos : _minAndroid).text = '$_mine'),
                        child: Text('خلّي أقل نسخة = نسخة موبايلي ($_mine)'),
                      ),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'بيتحفظ…' : 'احفظ')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
