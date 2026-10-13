import 'package:flutter/material.dart';
import '../../manager/widgets/match_clock_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../manager/view/manager_match_screen.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/view/match_center_screen.dart';
import '../../matches/widgets/match_format.dart';
import '../cubit/tournament_cubit.dart';

/// ماتشات البطولة بالدور (مجموعة A · ربع النهائي …): الضغط = صفحة الماتش. المنظّم: يحدد ميعاد كل ماتش
/// (القرعة بتعمل الماتشات من غير ميعاد) · إدارة الماتش · ولو تعادل في خروج المغلوب يختار الفايز (ضربات جزاء).
class TournamentMatchesTab extends StatelessWidget {
  const TournamentMatchesTab({super.key, required this.state, required this.runs});
  final TournamentState state;
  final bool runs;

  @override
  Widget build(BuildContext context) {
    if (state.matches.isEmpty) {
      return Center(
        child: Text('الماتشات بتتعمل بعد القرعة', style: AppText.body(13, color: AppColors.neutral600)),
      );
    }
    final byStage = <String, List<GameMatch>>{};
    for (final m in state.matches) {
      byStage.putIfAbsent(m.stage ?? 'ماتشات', () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        if (runs && state.matches.any((m) => !m.timeSet))
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
            child: Text(
              'القرعة اتعملت — حدّد ميعاد كل ماتش من زرار «حدّد الميعاد». الماتش مبيظهرش للناس ولا بيتلعب '
              'غير لما ميعاده يتحدد، وبعدها تقدر تحط التشكيلة والأحداث عادي.',
              style: AppText.body(12, color: AppColors.accent700),
            ),
          ),
        for (final e in byStage.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(e.key, style: AppText.kicker(color: AppColors.accent, size: 11)),
          ),
          for (final m in e.value) _row(context, m),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, GameMatch m) {
    final needsWinner =
        runs &&
        m.isFinished &&
        m.winner == null &&
        m.scoreA == m.scoreB &&
        m.stage != null &&
        !m.stage!.startsWith('مجموعة') &&
        m.stage != 'الدوري';
    final live = m.timeSet && m.hasStarted && !m.isFinished;
    final canSetTime = runs && !m.isFinished && !live;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: m.timeSet ? () => MatchCenterScreen.open(context, m) : null,
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.all(14),
        decoration: AppDecor.tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.teamA,
                    textAlign: TextAlign.end,
                    style: AppText.h(14, color: _c(m, m.teamA)),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: live ? AppColors.danger : AppColors.black,
                    borderRadius: AppRadius.md,
                  ),
                  child: Text(
                    m.isFinished || live
                        ? '${m.scoreA ?? 0} - ${m.scoreB ?? 0}'
                        : (m.timeSet ? arabicTime(m.dateTime) : 'ضد'),
                    style: AppText.h(13, color: AppColors.white),
                  ),
                ),
                Expanded(
                  child: Text(m.teamB, style: AppText.h(14, color: _c(m, m.teamB))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              m.timeSet
                  ? '${arabicWeekday(m.dateTime)} ${m.dateTime.day}/${m.dateTime.month}${m.winner != null && m.scoreA == m.scoreB ? ' · ${m.winner} كسب بضربات الجزاء' : ''}'
                  : 'الميعاد لسه متحددش',
              textAlign: TextAlign.center,
              style: AppText.body(10, color: AppColors.neutral600),
            ),
            if (needsWinner)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('تعادل — مين كسب بضربات الجزاء؟', style: AppText.h(12, color: AppColors.bronze)),
                    ),
                    for (final team in m.teams)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: OutlinedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final err = await context.read<TournamentCubit>().setWinner(m.id, team);
                            messenger.showSnackBar(SnackBar(content: Text(err ?? '$team اتأهل ✓')));
                          },
                          child: Text(team),
                        ),
                      ),
                  ],
                ),
              ),
            if (runs && !m.isFinished)
              Wrap(
                alignment: WrapAlignment.end,
                children: [
                  if (canSetTime)
                    TextButton.icon(
                      onPressed: () => _pickTime(context, m),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(m.timeSet ? 'غيّر الميعاد' : 'حدّد الميعاد'),
                    ),
                  if (m.timeSet)
                    TextButton.icon(
                      onPressed: () =>
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ManagerMatchScreen.of(context, m))),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('إدارة الماتش'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// المنظّم بيختار اليوم والساعة → الميعاد بيتحفظ وأهل المنطقة بيوصلهم إشعار.
  Future<void> _pickTime(BuildContext context, GameMatch m) async {
    final cubit = context.read<TournamentCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final now = DateTime.now();
    final start = m.timeSet && m.dateTime.isAfter(now) ? m.dateTime : now.add(const Duration(hours: 2));
    final day = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: '${m.teamA} ضد ${m.teamB}',
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(start));
    if (time == null) return;
    if (!context.mounted) return;
    final at = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    // المدة (الافتراضي ساعة) — الماتش بيتقفل لوحده بعدها
    var duration = m.durationMin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: AppColors.bg,
          title: Text('مدة الماتش', style: AppText.h(16)),
          content: DurationChips(value: duration, onChanged: (d) => set(() => duration = d)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('تمام')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final err = await cubit.setMatchTime(m.id, at, duration);
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'اتحدد الميعاد ✓ ${arabicWeekday(at)} ${at.day}/${at.month} ${arabicTime(at)}')),
    );
  }

  /// الفايز بالأخضر بعد الماتش.
  static Color _c(GameMatch m, String team) => m.isFinished && m.winner == team
      ? AppColors.accent
      : (m.isFinished && m.winner != null ? AppColors.neutral500 : AppColors.ink);
}
