import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import 'motion.dart';

/// إجراء على المحدّدين (احذف · رجّعهم يوزرز …).
typedef SelectionAction = ({String label, Color color, VoidCallback? onTap});

/// شريط التحديد فوق قايمة: "تحديد" → عدد المحدّد + حدد الكل + الإجراءات + إلغاء.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.title,
    required this.selecting,
    required this.selected,
    required this.total,
    required this.onStart,
    required this.onCancel,
    required this.onSelectAll,
    this.actions = const [],
  });

  final String title;
  final bool selecting;
  final int selected;
  final int total;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onSelectAll;
  final List<SelectionAction> actions;

  @override
  Widget build(BuildContext context) {
    if (!selecting) {
      return Row(
        children: [
          Expanded(child: Text(title, style: AppText.h(15))),
          if (total > 0) _chip('☑ تحديد', AppColors.ink, onStart, outlined: true),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('محدّد $selected من $total', style: AppText.h(14))),
            _chip(selected == total ? 'شيل التحديد' : 'حدد الكل', AppColors.info, onSelectAll, outlined: true),
            const SizedBox(width: 6),
            _chip('إلغاء', AppColors.neutral700, onCancel, outlined: true),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final a in actions) _chip(a.label, a.color, a.onTap)]),
      ],
    );
  }

  Widget _chip(String label, Color color, VoidCallback? onTap, {bool outlined = false}) => Pressable(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: outlined ? null : color,
          borderRadius: AppRadius.md,
          border: Border.all(color: color, width: 1.2),
        ),
        child: Text(label, style: AppText.h(12, color: outlined ? color : AppColors.white)),
      ),
    ),
  );
}

/// تأكيد إجراء على كذا حاجة. [typeToConfirm]: لازم يكتب الكلمة دي (للحذف الكبير زي "احذف الكل").
Future<bool> confirmBulk(BuildContext context, String title, String message, {String? typeToConfirm}) async {
  final c = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (d) => StatefulBuilder(
      builder: (d, setState) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text(title, style: AppText.h(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: AppText.body(13)),
            if (typeToConfirm != null) ...[
              const SizedBox(height: 10),
              Text('اكتب «$typeToConfirm» للتأكيد', style: AppText.body(11, color: AppColors.danger)),
              TextField(controller: c, onChanged: (_) => setState(() {})),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text('إلغاء', style: AppText.h(13, color: AppColors.neutral700)),
          ),
          TextButton(
            onPressed: typeToConfirm == null || c.text.trim() == typeToConfirm ? () => Navigator.pop(d, true) : null,
            child: Text('تأكيد', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    ),
  );
  c.dispose();
  return ok == true;
}
