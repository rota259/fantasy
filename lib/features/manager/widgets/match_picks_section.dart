import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../week/data/week_window.dart';
import '../data/admin_repository.dart';
import '../../../core/widgets/motion.dart';

/// (أدمن) كام واحد حفظ تشكيلة جولة الماتش ده + تذكير لأهل المنطقة (إشعار واحد مش لكل يوزر).
class MatchPicksSection extends StatefulWidget {
  const MatchPicksSection({super.key, required this.match});
  final GameMatch match;

  @override
  State<MatchPicksSection> createState() => _MatchPicksSectionState();
}

class _MatchPicksSectionState extends State<MatchPicksSection> {
  late final WeekWindow _round = WeekWindow.current(widget.match.dateTime);
  late Future<(int, int)> _future = _load();
  bool _sending = false;

  Future<(int, int)> _load() async {
    final repo = context.read<AdminRepository>();
    final (picked, counts) = await (repo.roundPickerCount(_round.cutoff), repo.counts()).wait;
    return (picked, counts.users);
  }

  Future<void> _remind() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await context.read<AdminRepository>().remindRound(widget.match.id);
      messenger.showSnackBar(const SnackBar(content: Text('اتبعت تذكير لأهل المنطقة ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'فشل الإرسال'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(int, int)>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) return Text('تعذّر التحميل', style: AppText.body(12, color: AppColors.danger));
        if (!snap.hasData) {
          return Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final (picked, users) = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('تشكيلات الجولة: $picked من $users يوزر', style: AppText.h(15))),
                Pressable(
                  onTap: () => setState(() {
                    _future = _load();
                  }),
                  child: Icon(Icons.refresh, size: 20, color: AppColors.neutral700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_round.label} · بتقفل ${arabicWeekday(_round.deadline)} ${arabicTime(_round.deadline)}',
              style: AppText.body(11, color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            if (!_round.isLocked())
              Pressable(
                onTap: _sending ? null : _remind,
                child: Container(
                  decoration: BoxDecoration(
                    color: _sending ? AppColors.neutral500 : AppColors.accent,
                    borderRadius: AppRadius.md,
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  child: Text('⏰ ذكّر أهل المنطقة بالتشكيلة', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
          ],
        );
      },
    );
  }
}
