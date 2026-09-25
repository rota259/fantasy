import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../data/admin_repository.dart';

/// (مدير) نتايج آخر تصويت + زرار قفله وإعلان الفايز بإشعار.
class ManagerPollResults extends StatefulWidget {
  const ManagerPollResults({super.key, required this.kind});
  final String kind; // goal_week | save_week | ...

  @override
  State<ManagerPollResults> createState() => _ManagerPollResultsState();
}

class _ManagerPollResultsState extends State<ManagerPollResults> {
  late Future<PollView?> _future = _load();
  bool _closing = false;

  Future<PollView?> _load() => context.read<PollsRepository>().latestPoll(widget.kind, '');

  Future<void> _close(PollView v) async {
    final messenger = ScaffoldMessenger.of(context);
    final polls = context.read<PollsRepository>();
    final admin = context.read<AdminRepository>();
    setState(() => _closing = true);
    try {
      await polls.closePoll(v.poll.id);
      final w = v.winner;
      await admin.notify(
        title: '🏆 ${v.poll.question}',
        body: w == null ? 'التصويت انتهى من غير أصوات' : '${w.label} — ${w.votes} من ${v.totalVotes} صوت',
        kind: 'vote',
      );
      messenger.showSnackBar(const SnackBar(content: Text('اتقفل التصويت واتعلن الفايز ✓')));
      setState(() {
        _future = _load();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل القفل: $e')));
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PollView?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
        final v = snap.data;
        if (v == null) return const SizedBox.shrink();
        final active = v.poll.active;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                active ? 'التصويت الحالي (مفتوح)' : 'آخر تصويت (مقفول)',
                style: AppText.kicker(color: active ? AppColors.accent : AppColors.neutral600),
              ),
              const SizedBox(height: 4),
              Text(v.poll.question, style: AppText.h(14)),
              const SizedBox(height: 8),
              for (final o in [...v.options]..sort((a, b) => b.votes.compareTo(a.votes)))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(o.label, style: AppText.body(12))),
                      Text('${o.votes} صوت', style: AppText.h(12)),
                    ],
                  ),
                ),
              Text('الإجمالي: ${v.totalVotes}', style: AppText.body(10, color: AppColors.neutral600)),
              if (active) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _closing ? null : () => _close(v),
                  child: Container(
                    color: _closing ? AppColors.neutral500 : AppColors.black,
                    padding: const EdgeInsets.all(11),
                    alignment: Alignment.center,
                    child: Text('🏆 اقفل وأعلن الفايز', style: AppText.h(13, color: AppColors.white)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
