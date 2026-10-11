import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../integrity/widgets/note_dialog.dart';
import '../data/team.dart';
import '../data/teams_repository.dart';
import '../widgets/team_players_card.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// (مدير) فرقي: كل فريق وتحته لاعيبته — من هنا بضيف الفرق واللاعيبة (بصورهم) وأحذفهم.
class MyTeamsScreen extends StatefulWidget {
  const MyTeamsScreen({super.key, required this.userId});
  final String userId;

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen> {
  late final TeamsRepository _repo = context.read<TeamsRepository>();
  late Future<List<Team>> _future = _repo.mine(widget.userId);

  void _reload() => setState(() {
    _future = _repo.mine(widget.userId);
  });

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _add() async {
    final name = await showNoteDialog(context, title: 'فريق جديد', hint: 'اسم الفريق (مميّز — مثلًا: نسور بدر)');
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => _repo.create(name), 'اتضاف «$name» ✓');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'فرقي',
            subtitle: 'ORGANIZER · TEAMS',
            onBack: () => Navigator.pop(context),
            trailing: Pressable(
              onTap: _add,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: AppRadius.md, border: AppBorders.white(0.5)),
                child: Text('+ فريق', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Team>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'اسم الفريق مميّز في الأبلكيشن كله ومبيتغيّرش، والماتش لازم يكون بين فريقين من فرقك. '
                        'افتح أي فريق وضيف لاعيبته بصورهم — الصورة بتظهر في التشكيلات وتشكيلة الجولة.',
                        style: AppText.body(12, color: AppColors.neutral700),
                      ),
                    ),
                    if (snap.data!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: EmptyState(
                          icon: Icons.shield_outlined,
                          title: 'لسه معملتش فرق',
                          hint: 'اضغط «+ فريق» فوق، وبعدها ضيف لاعيبته',
                        ),
                      ),
                    // كل فريق وتحته لاعيبته (أول فريق مفتوح)
                    for (final (i, t) in snap.data!.indexed)
                      TeamPlayersCard(
                        key: ValueKey(t.id),
                        team: t,
                        initiallyOpen: i == 0,
                        onDeleteTeam: () => _run(() => _repo.delete(t.id), 'اتحذف ✓'),
                      ),
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
