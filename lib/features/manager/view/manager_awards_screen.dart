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

/// (مدير) هدف/تصدّي الجولة: المرشّحين بلينكات الفيديو + النتايج + تصويت الموسم.
class ManagerAwardsScreen extends StatefulWidget {
  const ManagerAwardsScreen({super.key});

  @override
  State<ManagerAwardsScreen> createState() => _ManagerAwardsScreenState();
}

class _ManagerAwardsScreenState extends State<ManagerAwardsScreen> {
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

  /// شيل مرشّح — الـ controller بيتقفل بعد ما الحقل يختفي من الشاشة.
  void _remove(int i) {
    final c = _cands.removeAt(i);
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  /// التصويت بيقفل نص ليل الجمعة (آخر يوم عرض الجولة).
  DateTime get _closesAt {
    var w = WeekWindow.current();
    if (DateTime.now().isAfter(w.cutoff.add(const Duration(hours: 20)))) w = w.next;
    return w.cutoff.add(const Duration(hours: 20));
  }

  Future<void> _publish(List<Player> players) async {
    final messenger = ScaffoldMessenger.of(context);
    final opts = <NewPollOption>[];
    for (final c in _cands) {
      final link = c.link.text.trim();
      if (c.playerId == null) continue;
      if (!VideoLink.isValid(link)) {
        messenger.showSnackBar(const SnackBar(content: Text('كل مرشّح لازم يبقى معاه لينك فيديو صحيح')));
        return;
      }
      final p = players.firstWhere((x) => x.id == c.playerId);
      opts.add((label: '${p.name} · ${p.team}', playerId: p.id, videoUrl: link, matchId: null));
    }
    if (opts.length < 2) {
      messenger.showSnackBar(const SnackBar(content: Text('محتاج مرشّحين اتنين على الأقل')));
      return;
    }
    setState(() => _busy = true);
    try {
      final kind = _kind == 'goal' ? PollKind.goalWeek : PollKind.saveWeek;
      await context.read<PollsRepository>().createAward(
        kind,
        _kind == 'goal' ? 'هدف الجولة ⚽' : 'تصدّي الجولة 🧤',
        opts,
        _closesAt,
      );
      messenger.showSnackBar(const SnackBar(content: Text('اتنشر التصويت ✓')));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _season() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PollsRepository>().createSeasonAward(_kind);
      messenger.showSnackBar(const SnackBar(content: Text('اتعمل تصويت الموسم من فايزين الجولات ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
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
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                final players = snap.data!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [_kindTab('goal', 'هدف ⚽'), const SizedBox(width: 8), _kindTab('save', 'تصدّي 🧤')]),
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
                    Text('آخر الموسم', style: AppText.kicker()),
                    const SizedBox(height: 6),
                    Text(
                      'تصويت بين كل اللي كسبوا ${_kind == 'goal' ? 'هدف' : 'تصدّي'} الجولة في الموسم.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 8),
                    _button('🏆 اعمل تصويت ${_kind == 'goal' ? 'هدف' : 'تصدّي'} الموسم', AppColors.black, _season),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindTab(String k, String label) {
    final on = _kind == k;
    return Pressable(
      onTap: () => setState(() => _kind = k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent : null,
          border: Border.all(color: on ? AppColors.accent : AppColors.black, width: 2),
        ),
        child: Text(label, style: AppText.h(13, color: on ? AppColors.white : AppColors.ink)),
      ),
    );
  }

  Widget _button(String text, Color color, VoidCallback? onTap, {bool dark = true}) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: onTap == null ? AppColors.neutral500 : color,
        border: dark ? null : Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Text(text, style: AppText.h(13, color: dark ? AppColors.white : AppColors.ink)),
    ),
  );
}
