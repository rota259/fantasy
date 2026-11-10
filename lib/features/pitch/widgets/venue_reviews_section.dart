import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../data/models/venue.dart';
import '../data/models/venue_review.dart';
import '../data/reviews_repository.dart';
import 'review_sheet.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'venue_reviews_section_parts.dart';

/// تقييمات الملعب في صفحته: المتوسط + "قيّم" + آخر التعليقات.
class VenueReviewsSection extends StatefulWidget {
  const VenueReviewsSection({super.key, required this.venue, required this.userId});

  final Venue venue;
  final String userId;

  @override
  State<VenueReviewsSection> createState() => _VenueReviewsSectionState();
}

class _VenueReviewsSectionState extends State<VenueReviewsSection> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final ReviewsRepository _repo = context.read<ReviewsRepository>();
  late Future<List<VenueReview>> _future = _repo.list(widget.venue.id);

  bool get _isOwner => widget.venue.ownerId == widget.userId;
  late final bool _isAdmin = context.read<AuthCubit>().state.user?.isManager ?? false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VenueReview>>(
      future: _future,
      builder: (context, snap) {
        final list = snap.data ?? const <VenueReview>[];
        VenueReview? mine;
        for (final r in list) {
          if (r.userId == widget.userId) mine = r;
        }
        final avg = list.isEmpty ? 0.0 : list.fold(0, (s, r) => s + r.stars) / list.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('التقييمات والتعليقات', style: AppText.h(15)),
              const SizedBox(height: 8),
              // ملخّص: المتوسط بالنجوم + توزيع ٥..١ + زرار التقييم
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppDecor.tile,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          children: [
                            Text(list.isEmpty ? '—' : avg.toStringAsFixed(1), style: AppText.h(34, height: 1)),
                            _stars(avg.round(), 14),
                            Text('${list.length} تقييم', style: AppText.body(11, color: AppColors.neutral700)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(children: [for (var n = 5; n >= 1; n--) _bar(n, list)])),
                      ],
                    ),
                    if (!_isOwner) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _review(mine),
                          icon: const Icon(Icons.star_rate_rounded),
                          label: Text(mine == null ? 'قيّم الملعب واكتب تعليق' : 'عدّل تقييمك'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              if (!snap.hasData)
                Padding(padding: EdgeInsets.all(12), child: const SkeletonList())
              else if (list.isEmpty)
                Text('لسه محدش قيّم الملعب ده', style: AppText.body(12, color: AppColors.neutral600))
              else
                for (final r in list.take(10)) _row(r),
            ],
          ),
        );
      },
    );
  }
}
