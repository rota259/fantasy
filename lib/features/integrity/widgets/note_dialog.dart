import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// ديالوج نص قصير (سبب اعتراض / ملاحظة طلب) — بيرجّع النص أو null لو اتلغى.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  required String hint,
  bool required = true,
}) => showDialog<String>(
  context: context,
  builder: (_) => _NoteDialog(title: title, hint: hint, required: required),
);

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.title, required this.hint, required this.required});

  final String title;
  final String hint;
  final bool required;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(),
      title: Text(widget.title, style: AppText.h(16)),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 300,
        maxLines: 3,
        style: AppText.body(13),
        decoration: InputDecoration(hintText: widget.hint, border: const OutlineInputBorder()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        TextButton(
          onPressed: () {
            final t = _c.text.trim();
            if (widget.required && t.isEmpty) return;
            Navigator.pop(context, t);
          },
          child: const Text('ابعت'),
        ),
      ],
    );
  }
}
