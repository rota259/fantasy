import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../awards/data/video_link.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../../week/data/week_window.dart';
import '../widgets/award_candidate_field.dart';
import '../widgets/manager_poll_results.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'manager_awards_screen_sections.dart';

/// (مدير) هدف/تصدّي الجولة: المرشّحين بلينكات الفيديو + النتايج + تصويت الموسم.
class ManagerAwardsScreen extends StatefulWidget {
  const ManagerAwardsScreen({super.key});

  @override
  State<ManagerAwardsScreen> createState() => _ManagerAwardsScreenState();
}

class _ManagerAwardsScreenState extends State<ManagerAwardsScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final Future<List<Player>> _players = context.read<PlayersRepository>().fetchAll();
  final List<AwardCandidate> _cands = [AwardCandidate(), AwardCandidate()];
  String _kind = 'goal'; // goal | save
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _cands) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekKind = _kind == 'goal' ? PollKind.goalWeek : PollKind.saveWeek;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'هدف وتصدّي الجولة', subtitle: 'ADMIN · AWARDS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<Player>>(
              future: _players,
              builder: (context, snap) {
                if (!snap.hasData) return const SkeletonList();
                final players = snap.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [_kindTab('goal', 'هدف'), const SizedBox(width: 8), _kindTab('save', 'تصدّي 🧤')]),
                    ManagerPollResults(key: ValueKey(weekKind), kind: weekKind),
                    Text('مرشّحين جداد (التصويت بيقفل لوحده نص ليل الجمعة)', style: AppText.kicker()),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _cands.length; i++)
                      AwardCandidateField(
                        key: ObjectKey(_cands[i]),
                        index: i,
                        candidate: _cands[i],
                        players: players,
                        onChanged: () => setState(() {}),
                        onRemove: () => _remove(i),
                      ),
                    _button(
                      '+ مرشّح',
                      AppColors.white,
                      () => setState(() => _cands.add(AwardCandidate())),
                      dark: false,
                    ),
                    const SizedBox(height: 10),
                    _button(
                      _busy ? 'بيتنشر…' : 'انشر التصويت',
                      AppColors.accent,
                      _busy ? null : () => _publish(players),
                    ),
                    const SizedBox(height: 22),
                    Text('آخر السنة', style: AppText.kicker()),
                    const SizedBox(height: 6),
                    Text(
                      'تصويت بين كل اللي كسبوا ${_kind == 'goal' ? 'هدف' : 'تصدّي'} الجولة في السنة دي.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 8),
                    _button('اعمل تصويت ${_kind == 'goal' ? 'هدف' : 'تصدّي'} السنة', AppColors.black, _season),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
