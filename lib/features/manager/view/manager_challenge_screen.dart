import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_mode.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// تحدّي الجولة: مدير المنطقة بيختار ماتش من ماتشاته (واحد في الجولة)، والأدمن من أي ماتش.
/// يوزرز منطقة الماتش بس بيتوقّعوا — اللي يجيب فرق الأهداف صح ياخد +٥.
class ManagerChallengeScreen extends StatefulWidget {
  const ManagerChallengeScreen({super.key, this.organizerId});

  /// مدير المنطقة (ماتشاته بس) — null = الأدمن.
  final String? organizerId;

  @override
  State<ManagerChallengeScreen> createState() => _ManagerChallengeScreenState();
}

class _ManagerChallengeScreenState extends State<ManagerChallengeScreen> {
  late final MatchesRepository _matches = context.read<MatchesRepository>();
  late Future<List<GameMatch>> _future = _load();
  bool _busy = false;

  /// الماتشات اللي فاضل عليها أكتر من ساعتين (الناس تلحق تتوقّع).
  Future<List<GameMatch>> _load() async {
    final id = widget.organizerId;
    final all = id == null ? await _matches.fetchAll() : await _matches.fetchOrganizedBy(id);
    final from = DateTime.now().add(Duration(hours: kTestMode ? 0 : 2));
    return all.where((m) => !m.isFinished && m.dateTime.isAfter(from)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Future<void> _choose(GameMatch m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('تحدّي الجولة', style: AppText.h(16)),
        content: Text('${m.teamA} ضد ${m.teamB} — هيتبعت إشعار ليوزرز المنطقة يتوقّعوا.', style: AppText.body(13)),
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
          Masthead(
            title: 'تحدّي الجولة',
            subtitle: widget.organizerId == null ? 'ADMIN · CHALLENGE' : 'CHALLENGE',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<GameMatch>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const SkeletonList();
                final list = snap.data!;
                final open = list.where((m) => !m.isChallenge).toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'اختار ماتش من ماتشاتك (تحدّي واحد في الجولة) — يوزرز منطقتك يتوقّعوا، '
                      'واللي يجيب فرق الأهداف صح (مثلًا ٣-١ والنتيجة ٢-٠) ياخد +٥ بعد اعتماد الماتش.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 12),
                    Pressable(
                      onTap: _busy || open.isEmpty ? null : () => _choose(open[Random().nextInt(open.length)]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _busy || open.isEmpty ? AppColors.neutral500 : AppColors.black,
                          borderRadius: AppRadius.md,
                        ),
                        padding: const EdgeInsets.all(13),
                        alignment: Alignment.center,
                        child: Text('🎲 اختار ماتش عشوائي', style: AppText.h(14, color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (list.isEmpty)
                      Text(
                        'مفيش ماتشات فاضل عليها أكتر من ساعتين',
                        style: AppText.body(12, color: AppColors.neutral600),
                      ),
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
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: AppDecor.softDivider,
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
          Pressable(
            onTap: _busy ? null : () => _choose(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: Text('اختار', style: AppText.h(11)),
            ),
          ),
      ],
    ),
  );
}
