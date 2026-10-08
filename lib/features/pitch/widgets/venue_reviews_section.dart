import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../data/models/venue.dart';
import '../data/models/venue_review.dart';
import '../data/reviews_repository.dart';
import 'review_sheet.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// تقييمات الملعب في صفحته: المتوسط + "قيّم" + آخر التعليقات.
class VenueReviewsSection extends StatefulWidget {
  const VenueReviewsSection({super.key, required this.venue, required this.userId});

  final Venue venue;
  final String userId;

  @override
  State<VenueReviewsSection> createState() => _VenueReviewsSectionState();
}

class _VenueReviewsSectionState extends State<VenueReviewsSection> {
  late final ReviewsRepository _repo = context.read<ReviewsRepository>();
  late Future<List<VenueReview>> _future = _repo.list(widget.venue.id);

  bool get _isOwner => widget.venue.ownerId == widget.userId;
  late final bool _isAdmin = context.read<AuthCubit>().state.user?.isManager ?? false;

  /// (أدمن) مسح تقييم مسيء.
  Future<void> _remove(VenueReview r) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.delete(widget.venue.id, r.userId);
      setState(() {
        _future = _repo.list(widget.venue.id);
      });
      messenger.showSnackBar(const SnackBar(content: Text('اتمسح التقييم ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _review(VenueReview? mine) async {
    final input = await showReviewSheet(context, mine);
    if (input == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.save(widget.venue.id, widget.userId, input.stars, input.comment);
      setState(() {
        _future = _repo.list(widget.venue.id);
      });
      messenger.showSnackBar(const SnackBar(content: Text('اتنشر تقييمك ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

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
              Row(
                children: [
                  Text('التقييمات', style: AppText.h(15)),
                  const SizedBox(width: 8),
                  if (list.isNotEmpty)
                    Text('★ ${avg.toStringAsFixed(1)} (${list.length})', style: AppText.h(13, color: AppColors.gold)),
                  const Spacer(),
                  if (!_isOwner)
                    Pressable(
                      onTap: () => _review(mine),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md,
                          border: Border.all(color: AppColors.line, width: 1.2),
                        ),
                        child: Text(mine == null ? '★ قيّم' : 'عدّل تقييمك', style: AppText.h(11)),
                      ),
                    ),
                ],
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

  Widget _row(VenueReview r) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: AppDecor.softDivider,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PentagonAvatar(
          initials: r.name.trim().length >= 2 ? r.name.trim().substring(0, 2) : '؟',
          photoUrl: r.photoUrl,
          size: 30,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(r.name.isEmpty ? 'يوزر' : r.name, style: AppText.h(12))),
                  Text('★' * r.stars, style: AppText.h(12, color: AppColors.gold)),
                  if (_isAdmin && r.userId != widget.userId)
                    Pressable(
                      onTap: () => _remove(r),
                      child: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                      ),
                    ),
                ],
              ),
              if (r.comment != null) Text(r.comment!, style: AppText.body(12)),
            ],
          ),
        ),
      ],
    ),
  );
}
