import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../cubit/manager_match_cubit.dart';

/// النتيجة: بتتحسب لوحدها من الأهداف المسجّلة (مفيش كتابة يدوي) — المدير بس بينهي الماتش.
/// السيرفر بيبعت إشعار النتيجة، ولو مدير منطقة بيبدأ تأكيد اللاعيبة.
class MatchResultSection extends StatefulWidget {
  const MatchResultSection({super.key, required this.match, required this.isAdmin, required this.cubit});
  final GameMatch match;
  final bool isAdmin;
  final ManagerMatchCubit cubit;

  @override
  State<MatchResultSection> createState() => _MatchResultSectionState();
}

class _MatchResultSectionState extends State<MatchResultSection> {
  late bool _finished = widget.match.isFinished;
  bool _saving = false;

  Future<void> _finish() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('إنهاء الماتش؟', style: AppText.h(16)),
        content: Text(
          'النتيجة هتتسجّل زي ما هي من الأهداف واليوزرز هيوصلهم إشعار.'
          '${widget.isAdmin ? '' : '\n\n⚠️ بعد ما الماتش يخلص مش هتقدر تعدّل أي حاجة فيه (لا تشكيلة ولا أحداث) — اتأكد إن كل حاجة صح.'}',
          style: AppText.body(13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('لسه')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('أنهيه')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<MatchesRepository>().finishMatch(widget.match.id);
      if (!mounted) return;
      setState(() => _finished = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isAdmin ? 'الماتش خلص واتبعت إشعار ✓' : 'الماتش خلص ✓ — لاعيبة الفريقين هيوصلهم طلب تأكيد',
          ),
        ),
      );
      // المنظّم: الماتش اتقفل — نرجع بره الإدارة
      if (!widget.isAdmin) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'فشل الحفظ'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final score = widget.cubit.score;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
          child: Row(
            children: [
              Expanded(child: _team(m.teamA)),
              CountUp(
                value: score.a,
                style: AppText.h(40, color: AppColors.white),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('-', style: AppText.h(30, color: AppColors.white)),
              ),
              CountUp(
                value: score.b,
                style: AppText.h(40, color: AppColors.white),
              ),
              Expanded(child: _team(m.teamB)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'النتيجة بتتحدّث لوحدها مع كل جول تسجّله في تاب "الأحداث" (والجول العكسي للفريق التاني). '
          '${widget.isAdmin ? '' : 'بعد الإنهاء لاعيبة الفريقين يأكدوا الورقة، ولو محدش اعترض النقط بتتعتمد.'}',
          style: AppText.body(11, color: AppColors.neutral700),
        ),
        const SizedBox(height: 16),
        if (_finished)
          Text('الماتش خلص ✓ — لو فيه جول غلط عدّله من تاب "الأحداث"', style: AppText.h(13, color: AppColors.accent))
        else
          Pressable(
            onTap: _saving ? null : _finish,
            child: Container(
              decoration: BoxDecoration(
                color: _saving ? AppColors.neutral500 : AppColors.accent,
                borderRadius: AppRadius.md,
              ),
              padding: const EdgeInsets.all(13),
              alignment: Alignment.center,
              child: Text('🏁 إنهاء الماتش', style: AppText.h(14, color: AppColors.white)),
            ),
          ),
      ],
    );
  }

  Widget _team(String t) => Text(
    t,
    textAlign: TextAlign.center,
    maxLines: 2,
    style: AppText.h(13, color: AppColors.white),
  );
}
