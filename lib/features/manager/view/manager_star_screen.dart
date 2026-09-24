import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../polls/data/polls_repository.dart';
import '../widgets/manager_poll_results.dart';

/// شاشة المدير: يعمل تصويت "نجم الجولة" بمرشّحين من اللاعيبة.
class ManagerStarScreen extends StatefulWidget {
  const ManagerStarScreen({super.key, required this.playersRepo, required this.pollsRepo});

  final PlayersRepository playersRepo;
  final PollsRepository pollsRepo;

  @override
  State<ManagerStarScreen> createState() => _ManagerStarScreenState();
}

class _ManagerStarScreenState extends State<ManagerStarScreen> {
  late final Future<List<Player>> _future = widget.playersRepo.fetchAll();
  final Set<String> _selected = {};

  Future<void> _publish(List<Player> players) async {
    final picked = players.where((p) => _selected.contains(p.id)).toList();
    if (picked.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختار مرشّحين على الأقل')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await widget.pollsRepo.createStar([for (final p in picked) (id: p.id, name: p.name)]);
    messenger.showSnackBar(const SnackBar(content: Text('اتنشر تصويت نجم الجولة ✓')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'نجم الجولة', subtitle: 'MANAGER · STAR', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<Player>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final players = snap.data!;
                if (players.isEmpty) {
                  return Center(child: Text('ضيف لاعيبة الأول', style: AppText.body(13, color: AppColors.neutral600)));
                }
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('اختار المرشّحين لنجم الجولة، واليوزرز يصوّتوا.',
                        style: AppText.body(12, color: AppColors.neutral700)),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const ManagerPollResults(kind: 'star'),
                        for (final p in players) _row(p),
                      ],
                    ),
                  ),
                  _publishBar(players),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Player p) {
    final on = _selected.contains(p.id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => on ? _selected.remove(p.id) : _selected.add(p.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
        child: Row(children: [
          Icon(on ? Icons.check_box : Icons.check_box_outline_blank, size: 20,
              color: on ? AppColors.accent : AppColors.neutral500),
          const SizedBox(width: 12),
          Expanded(child: Text(p.name, style: AppText.h(14))),
          Text('${p.team} · ${p.positionAr}', style: AppText.body(10, color: AppColors.neutral700)),
        ]),
      ),
    );
  }

  Widget _publishBar(List<Player> players) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => _publish(players),
          child: Container(
            color: AppColors.accent,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text('انشر التصويت (${_selected.length})', style: AppText.h(14, color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}
