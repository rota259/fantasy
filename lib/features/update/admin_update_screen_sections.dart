part of 'admin_update_screen.dart';

extension _AdminUpdateScreenStateSections1 on _AdminUpdateScreenState {
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
    if (mounted) _update(() => _loading = false);
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
    _update(() => _saving = true);
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
      if (mounted) _update(() => _saving = false);
    }
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
