import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../integrity/data/integrity_repository.dart';
import '../../integrity/data/models/pending_review.dart';
import '../../integrity/view/match_review_screen.dart';

/// ماتشات ضد فرقي مستنية تأكيدي كابتن (تأكيدي = اعتماد فوري، واعتراضي = الإدارة تحكم).
class CaptainReviews extends StatefulWidget {
  const CaptainReviews({super.key});

  @override
  State<CaptainReviews> createState() => _CaptainReviewsState();
}

class _CaptainReviewsState extends State<CaptainReviews> {
  late Future<List<PendingReview>> _f = _load();

  Future<List<PendingReview>> _load() =>
      context.read<IntegrityRepository>().myPendingReviews().catchError((_) => const <PendingReview>[]);

  Future<void> _open(PendingReview r) async {
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MatchReviewScreen(match: r.match)),
    );
    if (done == true && mounted) setState(() => _f = _load());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<PendingReview>>(
    future: _f,
    builder: (context, snap) => Column(
      children: [
        for (final r in snap.data ?? const <PendingReview>[])
          GestureDetector(
            onTap: () => _open(r),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
              child: Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: AppColors.accent400),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أكّد نتيجة ${r.match.teamA} ضد ${r.match.teamB} — إنت كابتن الخصم',
                      style: AppText.h(13, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
