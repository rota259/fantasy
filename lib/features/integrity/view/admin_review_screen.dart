import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/widgets/match_format.dart';
import '../data/integrity_repository.dart';
import '../data/models/match_flags.dart';
import '../data/models/review_case.dart';
import '../widgets/review_status_chip.dart';
import 'admin_case_screen.dart';

/// (أدمن) طابور المراجعة: الاعتراضات الأول، وبعدها الماتشات المعلّم عليها.
class AdminReviewScreen extends StatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  State<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends State<AdminReviewScreen> {
  late final IntegrityRepository _repo = context.read<IntegrityRepository>();
  late Future<List<ReviewCase>> _future = _repo.reviewQueue();

  Future<void> _open(ReviewCase c) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminCaseScreen(reviewCase: c)),
    );
    if (changed == true && mounted) {
      setState(() {
        _future = _repo.reviewQueue();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'مراجعة الماتشات', subtitle: 'ADMIN · REVIEW', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<ReviewCase>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                if (snap.data!.isEmpty) {
                  return Center(
                    child: Text('مفيش ماتشات محتاجة مراجعة ✓', style: AppText.body(13, color: AppColors.neutral600)),
                  );
                }
                return ListView(padding: EdgeInsets.zero, children: [for (final c in snap.data!) _row(c)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(ReviewCase c) {
    final m = c.match;
    final objections = c.votes.where((v) => !v.ok).length;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(c),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('${m.teamA} ${m.scoreText} ${m.teamB}', style: AppText.h(14))),
                ReviewStatusChip(match: m),
              ],
            ),
            Text(
              'منظّم: ${c.organizerName} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}'
              '${objections > 0 ? ' · $objections اعتراض' : ''}',
              style: AppText.body(11, color: AppColors.neutral700),
            ),
            if (m.flags.isNotEmpty)
              Text(m.flags.map(MatchFlags.label).join(' · '), style: AppText.body(11, color: AppColors.bronze)),
          ],
        ),
      ),
    );
  }
}
