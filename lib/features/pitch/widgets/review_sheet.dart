import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/models/venue_review.dart';
import '../../../core/widgets/motion.dart';

/// نتيجة شيت التقييم: نجوم + تعليق.
typedef ReviewInput = ({int stars, String comment});

/// شيت "قيّم الملعب": ٥ نجوم + تعليق اختياري.
Future<ReviewInput?> showReviewSheet(BuildContext context, VenueReview? mine) {
  return showModalBottomSheet<ReviewInput>(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => _ReviewSheet(mine: mine),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({this.mine});
  final VenueReview? mine;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _stars = widget.mine?.stars ?? 0;
  late final _comment = TextEditingController(text: widget.mine?.comment ?? '');

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('قيّم الملعب', style: AppText.h(18)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Pressable(
                      onTap: () => setState(() => _stars = i),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(i <= _stars ? Icons.star : Icons.star_border, size: 38, color: AppColors.gold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line, width: 1.2),
                ),
                child: TextField(
                  controller: _comment,
                  maxLines: 3,
                  maxLength: 500,
                  style: AppText.body(13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'اكتب رأيك (النجيلة، الإضاءة، المعاملة…) — اختياري',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Pressable(
                onTap: _stars == 0 ? null : () => Navigator.pop(context, (stars: _stars, comment: _comment.text)),
                child: Container(
                  decoration: BoxDecoration(
                    color: _stars == 0 ? AppColors.neutral500 : AppColors.accent,
                    borderRadius: AppRadius.md,
                  ),
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text(
                    _stars == 0 ? 'اختار عدد النجوم' : 'انشر التقييم',
                    style: AppText.h(14, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
