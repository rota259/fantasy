import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/admin_repository.dart';

/// رسايل جاهزة (عنوان، نص) يختار منها المدير ويعدّل عليها.
const _templates = [
  ('الماتش اتأجّل ⏳', 'الماتش اتأجّل — الميعاد الجديد هيتبعت قريب'),
  ('الملعب اتغيّر 📍', 'الماتش هيتلعب في ملعب تاني — شوف التفاصيل'),
  ('الديدلاين قرّب ⏰', 'فاضل ساعة على قفل التشكيلة — لحّق نزّل تشكيلتك'),
  ('ماتش ملغي ❌', 'الماتش اتلغى النهارده'),
];

/// (مدير) يبعت إشعار بأي رسالة لكل اليوزرز.
class ManagerBroadcastScreen extends StatefulWidget {
  const ManagerBroadcastScreen({super.key});

  @override
  State<ManagerBroadcastScreen> createState() => _ManagerBroadcastScreenState();
}

class _ManagerBroadcastScreenState extends State<ManagerBroadcastScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (title.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('اكتب عنوان الإشعار')));
      return;
    }
    setState(() => _sending = true);
    try {
      final pushed = await context.read<AdminRepository>().notify(title: title, body: body);
      _title.clear();
      _body.clear();
      messenger.showSnackBar(SnackBar(
        content: Text(pushed ? 'اتبعت لكل اليوزرز ✓' : 'اتسجّل جوه التطبيق (الـ push مبعتش)'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const StatusArea(),
        Masthead(title: 'إشعار للكل', subtitle: 'MANAGER · BROADCAST', onBack: () => Navigator.pop(context)),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text('رسايل جاهزة', style: AppText.kicker()),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final t in _templates)
                GestureDetector(
                  onTap: () => setState(() {
                    _title.text = t.$1;
                    _body.text = t.$2;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
                    child: Text(t.$1, style: AppText.body(12)),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            _field(_title, 'العنوان'),
            const SizedBox(height: 10),
            _field(_body, 'الرسالة (اختياري)', lines: 4),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                color: _sending ? AppColors.neutral500 : AppColors.accent,
                padding: const EdgeInsets.all(13),
                alignment: Alignment.center,
                child: Text('🔔 ابعت لكل اليوزرز', style: AppText.h(14, color: AppColors.white)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _field(TextEditingController c, String hint, {int lines = 1}) => Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
        child: TextField(
          controller: c,
          maxLines: lines,
          style: AppText.h(14),
          decoration: InputDecoration(
            isDense: true, border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            hintText: hint,
          ),
        ),
      );
}
