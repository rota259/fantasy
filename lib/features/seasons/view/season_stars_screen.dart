import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/widgets/match_format.dart';
import '../../week/data/team_of_week.dart';
import '../../week/data/week_repository.dart';
import '../../week/widgets/totw_pitch.dart';
import '../data/season.dart';
import '../data/seasons_repository.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// أبطال الموسم على مستوى كل المناطق: لاعب وتشكيلة النص الأول (بعد نص الموسم) والموسم كامل (بعد نهايته).
class SeasonStarsScreen extends StatefulWidget {
  const SeasonStarsScreen({super.key});

  @override
  State<SeasonStarsScreen> createState() => _SeasonStarsScreenState();
}

class _SeasonStarsScreenState extends State<SeasonStarsScreen> {
  late final Future<Season?> _season = _latest();
  bool _full = false;

  /// الموسم الحالي، ولو مفيش فآخر موسم بدأ.
  Future<Season?> _latest() async {
    final all = await context.read<SeasonsRepository>().fetchAll();
    final now = DateTime.now();
    return all.where((s) => s.isCurrent(now)).firstOrNull ?? all.where((s) => s.startsAt.isBefore(now)).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'أبطال الموسم', subtitle: 'كل المناطق · SEASON', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<Season?>(
              future: _season,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SkeletonList();
                }
                final s = snap.data;
                if (s == null) return _note('لسه مفيش موسم');
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [_tab('النص الأول', false), const SizedBox(width: 6), _tab('الموسم كامل', true)]),
                    const SizedBox(height: 16),
                    _period(s, _full ? s.endsAt : s.midAt),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _period(Season s, DateTime until) {
    if (DateTime.now().isBefore(until)) {
      return _note(
        'بتتعلن ${arabicWeekday(until)} ${until.day}/${until.month} — لما ${_full ? 'الموسم يخلص' : 'نص الموسم يعدّي'}',
      );
    }
    return FutureBuilder(
      key: ValueKey(until),
      future: context.read<WeekRepository>().pointsBetween(s.startsAt, until, allZones: true),
      builder: (context, snap) {
        if (!snap.hasData) return const SkeletonList();
        final ranked = snap.data!.where((p) => p.points > 0).toList();
        if (ranked.isEmpty) return _note('مفيش نقط في الفترة دي');
        final star = ranked.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('⭐ لاعب ${_full ? 'الموسم' : 'النص الأول'}', style: AppText.kicker(color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Text(star.name, style: AppText.h(22, color: AppColors.white)),
                  Text('${star.team} · ${star.points} نقطة', style: AppText.body(12, color: AppColors.accent400)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('تشكيلة ${_full ? 'الموسم' : 'النص الأول'}', style: AppText.kicker(color: AppColors.accent)),
            const SizedBox(height: 6),
            TotwPitch(spots: TeamOfWeek.arrange(ranked.take(TeamOfWeek.size).toList())),
            const SizedBox(height: 12),
            for (final (i, p) in ranked.take(10).indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}', style: AppText.h(14, color: AppColors.neutral600)),
                    ),
                    Expanded(child: Text('${p.name} · ${p.team}', style: AppText.h(13))),
                    Text('${p.points}', style: AppText.h(15, color: AppColors.accent)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tab(String label, bool full) => Expanded(
    child: Pressable(
      onTap: () => setState(() => _full = full),
      child: Container(
        padding: const EdgeInsets.all(11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: _full == full ? AppColors.accent : null,
          border: Border.all(color: _full == full ? AppColors.accent : AppColors.black, width: 2),
        ),
        child: Text(label, style: AppText.h(13, color: _full == full ? AppColors.white : AppColors.ink)),
      ),
    ),
  );

  Widget _note(String t) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: AppText.body(13, color: AppColors.neutral600),
    ),
  );
}
