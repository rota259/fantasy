import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/players_repository.dart';

/// قبل إضافة لاعب: لو فيه لاعيبة في المنطقة بنفس الاسم، نسأل المدير «ده نفس الشخص؟».
/// بيرجّع true = ضيفه (لاعب تاني)، false = متضيفوش (هو نفسه موجود).
Future<bool> confirmNotDuplicate(BuildContext context, String name, String team, {required bool hasNickname}) async {
  final List<Map<String, dynamic>> found;
  try {
    found = await context.read<PlayersRepository>().similar(name, team);
  } catch (_) {
    return true; // الفحص مساعدة بس — لو فشل منوقفش المدير
  }
  if (found.isEmpty || !context.mounted) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('فيه لاعب بنفس الاسم', style: AppText.h(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in found)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• ${p['name']}${p['nickname'] == null ? '' : ' (${p['nickname']})'} — ${p['team']}'
                '${p['verified'] == true ? ' ✓' : ''}',
                style: AppText.h(13),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            hasNickname
                ? 'لو هو نفس الشخص متضيفوش تاني. لو واحد تاني، اسم الشهرة هيفرّق بينهم.'
                : 'لو هو نفس الشخص متضيفوش تاني. لو واحد تاني، ارجع اكتبله اسم شهرة عشان الناس تفرّق بينهم.',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('هو نفسه — متضيفش')),
        TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('لا، ده لاعب تاني')),
      ],
    ),
  );
  return ok == true;
}
