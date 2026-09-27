import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/widgets/match_format.dart';
import '../data/admin_repository.dart';
import '../data/models/admin_log_entry.dart';

/// (أدمن) سجل العمليات: مين من الأدمنز عمل إيه وإمتى.
class AdminLogScreen extends StatelessWidget {
  const AdminLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'سجل العمليات', subtitle: 'ADMIN · LOG', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<AdminLogEntry>>(
              future: context.read<AdminRepository>().log(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                if (snap.data!.isEmpty) {
                  return Center(
                    child: Text('لسه مفيش عمليات', style: AppText.body(13, color: AppColors.neutral600)),
                  );
                }
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (final e in snap.data!)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.divider)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.label, style: AppText.h(13)),
                            Text(
                              '${e.adminName} · ${arabicWeekday(e.at)} ${e.at.day}/${e.at.month} ${arabicTime(e.at)}',
                              style: AppText.body(11, color: AppColors.neutral700),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
