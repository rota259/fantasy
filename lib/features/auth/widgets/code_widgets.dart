import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// حقل كود التأكيد: ٦ أرقام بس، كبير ومتباعد — وبيكمّل لوحده من رسالة الإيميل لو النظام عرضها.
class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, this.onDone});
  final TextEditingController controller;
  final VoidCallback? onDone;

  static const length = 6;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.line, width: 1.2),
    ),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      autofillHints: const [AutofillHints.oneTimeCode],
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(length)],
      style: AppText.h(26, spacingEm: 0.35),
      cursorColor: AppColors.accent,
      onChanged: (v) => v.length == length ? onDone?.call() : null,
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        hintText: '••••••',
        hintStyle: AppText.h(26, color: AppColors.neutral400, spacingEm: 0.35),
      ),
    ),
  );
}

/// «ابعت الكود تاني» بعدّاد ٦٠ ثانية (السيرفر كمان بيمنع الطلب المتكرر).
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({super.key, required this.onResend});

  /// بيرجّع رسالة خطأ أو null.
  final Future<String?> Function() onResend;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  static const _wait = 60;
  int _left = _wait;
  Timer? _timer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _left = _wait;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _tap() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final err = await widget.onResend();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'اتبعت كود جديد ✓')));
    if (err == null) setState(_start);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: _left > 0 || _busy ? null : _tap,
    child: Text(_left > 0 ? 'ابعت الكود تاني بعد $_left ثانية' : 'ابعت الكود تاني'),
  );
}
