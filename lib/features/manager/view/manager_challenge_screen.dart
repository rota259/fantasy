import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';

/// (مدير) تحدّي الجولة: اختار ماتش (أو عشوائي) واليوزرز يتوقّعوا نتيجته — الصح ياخد +٥.
class ManagerChallengeScreen extends StatefulWidget {
  const ManagerChallengeScreen({super.key});

  @override
  State<ManagerChallengeScreen> createState() => _ManagerChallengeScreenState();
}

class _ManagerChallengeScreenState extends State<ManagerChallengeScreen> {
  late final MatchesRepository _matches = context.read<MatchesRepository>();
  late Future<List<GameMatch>> _future = _load();
  bool _busy = false;

  /// الماتشات اللي لسه التوقّع فيها ممكن (قبل الديدلاين).
  Future<List<GameMatch>> _load() async => (await _matches.fetchUpcoming()).where((m) => !m.isLocked).toList();

  Future<void> _choose(GameMatch m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(),
        title: Text('تحدّي الجولة', style: AppText.h(16)),
        content: Text('${m.teamA} ضد ${m.teamB} — هيتبعت إشعار لكل اليوزرز يتوقّعوا النتيجة.', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('أعلن')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ChallengeRepository>();
    setState(() => _busy = true);
    try {
      await repo.setChallenge(m.id);
      messenger.showSnackBar(const SnackBar(content: Text('اتعلن التحدّي واتبعت إشعار ✓')));
      setState(() {
        _future = _load();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'تحدّي الجولة', subtitle: 'MANAGER · CHALLENGE', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<GameMatch>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final list = snap.data!;
                final open = list.where((m) => !m.isChallenge).toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'اختار ماتش — اليوزرز يتوقّعوا النتيجة بالظبط، واللي يجيبها صح ياخد +٥ لما تكتب النتيجة.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _busy || open.isEmpty ? null : () => _choose(open[Random().nextInt(open.length)]),
                      child: Container(
                        color: _busy || open.isEmpty ? AppColors.neutral500 : AppColors.black,
                        padding: const EdgeInsets.all(13),
                        alignment: Alignment.center,
                        child: Text('🎲 اختار ماتش عشوائي', style: AppText.h(14, color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (list.isEmpty)
                      Text('مفيش ماتشات جاية قبل الديدلاين', style: AppText.body(12, color: AppColors.neutral600)),
                    for (final m in list) _row(m),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(GameMatch m) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(14)),
              Text(
                '${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}',
                style: AppText.body(10, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
        if (m.isChallenge)
          Text('🎯 تحدّي', style: AppText.h(12, color: AppColors.accent))
        else
          GestureDetector(
            onTap: _busy ? null : () => _choose(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
              child: Text('اختار', style: AppText.h(11)),
            ),
          ),
      ],
    ),
  );
}
