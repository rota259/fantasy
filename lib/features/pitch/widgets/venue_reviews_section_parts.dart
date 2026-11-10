part of 'venue_reviews_section.dart';

extension _VenueReviewsSectionStateSections1 on _VenueReviewsSectionState {
  /// (أدمن) مسح تقييم مسيء.
  Future<void> _remove(VenueReview r) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.delete(widget.venue.id, r.userId);
      _update(() {
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
      _update(() {
        _future = _repo.list(widget.venue.id);
      });
      messenger.showSnackBar(const SnackBar(content: Text('اتنشر تقييمك ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _stars(int n, double size) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(i <= n ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.gold),
    ],
  );

  /// شريط توزيع: كام واحد إدّى [n] نجوم.
  Widget _bar(int n, List<VenueReview> list) {
    final c = list.where((r) => r.stars == n).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 14, child: Text('$n', style: AppText.body(11))),
          Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: list.isEmpty ? 0 : c / list.length,
                minHeight: 6,
                backgroundColor: AppColors.neutral200,
                color: AppColors.gold,
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Text('$c', textAlign: TextAlign.end, style: AppText.body(11)),
          ),
        ],
      ),
    );
  }

  Widget _row(VenueReview r) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: AppDecor.softDivider,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
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
                  _stars(r.stars, 13),
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
