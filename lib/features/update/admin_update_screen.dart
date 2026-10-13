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

/// (أدمن) التحديث الإجباري: أقل رقم نسخة مسموح لأندرويد وآيفون + لينكات المتجر + الرسالة.
/// أي جهاز نسخته أقدم من الرقم ده الأبلكيشن مبيفتحش عنده غير لما يحدّث.
class AdminUpdateScreen extends StatefulWidget {
  const AdminUpdateScreen({super.key});

  @override
  State<AdminUpdateScreen> createState() => _AdminUpdateScreenState();
}

class _AdminUpdateScreenState extends State<AdminUpdateScreen> {
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

  Future<void> _load() async {
    try {
      final cfg = Map<String, dynamic>.from(await SupabaseService.client.rpc('get_app_config') as Map);
      _mine = await AppBuild.number();
      _minAndroid.text = '${cfg['min_build_android'] ?? 0}';
      _minIos.text = '${cfg['min_build_ios'] ?? 0}';
      _storeAndroid.text = '${cfg['store_android'] ?? ''}';
      _storeIos.text = '${cfg['store_ios'] ?? ''}';
      _message.text = '${cfg['update_message'] ?? ''}';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_minAndroid, _minIos, _storeAndroid, _storeIos, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final minA = int.tryParse(_minAndroid.text.trim()) ?? 0;
    final minI = int.tryParse(_minIos.text.trim()) ?? 0;
    // تحذير: رقم أعلى من نسخة الأدمن نفسه = الأدمن كمان هيتقفل عليه
    final myMin = AppBuild.isIos ? minI : minA;
    if (myMin > _mine) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.bg,
          title: Text('متأكد؟', style: AppText.h(16)),
          content: Text(
            'الرقم اللي كتبته ($myMin) أعلى من نسخة موبايلك ($_mine). الأبلكيشن هيتقفل عليك إنت كمان لحد ما تحدّث — '
            'اتأكد إن النسخة $myMin نزلت على المتجر فعلًا قبل ما تحفظ.',
            style: AppText.body(13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('احفظ', style: AppText.h(13, color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _saving = true);
    try {
      for (final (k, v) in [
        ('store_android', _storeAndroid.text.trim()),
        ('store_ios', _storeIos.text.trim()),
        ('update_message', _message.text.trim()),
        ('min_build_android', '$minA'),
        ('min_build_ios', '$minI'),
      ]) {
        await SupabaseService.client.rpc('set_app_config', params: {'p_key': k, 'p_value': v});
      }
      messenger.showSnackBar(const SnackBar(content: Text('اتحفظ ✓ — أي نسخة أقدم هتطلعلها شاشة التحديث')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  Widget _field(TextEditingController c, String label, {bool number = false, int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: number ? TextInputType.number : (lines > 1 ? TextInputType.multiline : TextInputType.url),
      textDirection: number || lines > 1 ? null : TextDirection.ltr,
      decoration: InputDecoration(labelText: label),
    ),
  );
}
