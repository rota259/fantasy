import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

const _types = [('public', 'كلاسيك'), ('private', 'خاص')];

/// نتيجة "اعمل دوري".
typedef NewLeague = ({String name, String type});

/// ديالوج "انضم بكود" — بيرجّع الكود.
Future<String?> askInviteCode(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _TextDialog(title: 'انضم لدوري', hint: 'كود الدعوة', action: 'انضم'),
);

/// ديالوج "اعمل دوري" — بيرجّع الاسم والنوع.
Future<NewLeague?> askNewLeague(BuildContext context) =>
    showDialog<NewLeague>(context: context, builder: (_) => const _NewLeagueDialog());

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.hint, required this.action});
  final String title, hint, action;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(),
    title: Text(widget.title, style: AppText.h(16)),
    content: TextField(
      controller: _ctrl,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.hint),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      TextButton(onPressed: () => Navigator.pop(context, _ctrl.text.trim()), child: Text(widget.action)),
    ],
  );
}

class _NewLeagueDialog extends StatefulWidget {
  const _NewLeagueDialog();

  @override
  State<_NewLeagueDialog> createState() => _NewLeagueDialogState();
}

class _NewLeagueDialogState extends State<_NewLeagueDialog> {
  final _name = TextEditingController();
  String _type = 'private';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(),
    title: Text('اعمل دوري', style: AppText.h(16)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'اسم الدوري'),
        ),
        Row(
          children: [
            for (final t in _types) ...[
              GestureDetector(
                onTap: () => setState(() => _type = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _type == t.$1 ? AppColors.accent : null,
                    border: Border.all(color: _type == t.$1 ? AppColors.accent : AppColors.black, width: 2),
                  ),
                  child: Text(t.$2, style: AppText.h(12, color: _type == t.$1 ? AppColors.white : AppColors.ink)),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text('هتاخد كود تبعته لصحابك ينضموا بيه.', style: AppText.body(11, color: AppColors.neutral700)),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      TextButton(
        onPressed: () {
          final n = _name.text.trim();
          if (n.isNotEmpty) Navigator.pop(context, (name: n, type: _type));
        },
        child: const Text('اعمل'),
      ),
    ],
  );
}
