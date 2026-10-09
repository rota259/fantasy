import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/fairplay_repository.dart';

/// بلاغ مراهنات: على مين (اسم المدير/اليوزر/الفريق) + اللي حصل — بيروح للأدمنز يحققوا.
Future<void> showReportBettingSheet(BuildContext context) {
  final suspect = TextEditingController();
  final details = TextEditingController();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    builder: (c) => Padding(
      padding: EdgeInsets.fromLTRB(18, 8, 18, MediaQuery.viewInsetsOf(c).bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('🚫 بلّغ عن مراهنات', style: AppText.h(18)),
          const SizedBox(height: 4),
          Text(
            'البلاغ بيروح للإدارة بس، واسمك مش بيظهر لحد. الإدارة هتحقق، ولو اتثبت = بان نهائي.',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: suspect,
            maxLength: 120,
            decoration: const InputDecoration(hintText: 'على مين؟ (اسم المدير · اليوزر · الفريق · المنطقة)'),
          ),
          TextField(
            controller: details,
            maxLength: 1000,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'إيه اللي حصل؟ (إمتى · فين · أي دليل عندك)'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(c);
              final nav = Navigator.of(c);
              if (suspect.text.trim().length < 2 || details.text.trim().length < 10) {
                messenger.showSnackBar(const SnackBar(content: Text('اكتب على مين وإيه اللي حصل (١٠ حروف على الأقل)')));
                return;
              }
              try {
                await c.read<FairPlayRepository>().report(suspect.text, details.text);
                messenger.showSnackBar(
                  const SnackBar(content: Text('وصل البلاغ للإدارة ✓ — شكرًا إنك بتحافظ على اللعبة')),
                );
                nav.pop();
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
              }
            },
            child: const Text('ابعت البلاغ'),
          ),
        ],
      ),
    ),
  );
}
