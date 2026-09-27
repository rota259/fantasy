import 'package:flutter/material.dart';
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
import '../../../core/widgets/motion.dart';

/// (مدير) فرقي: اللي بعملها بس هي اللي أقدر أعمل بيها ماتشات وأضيف ليها لاعيبة.
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
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'اسم الفريق مميّز في الأبلكيشن كله ومبيتغيّرش. الماتش لازم يكون بين فريقين من فرقك، '
                        'واللاعيبة بتتضاف لفرقك من شاشة الماتش.',
                        style: AppText.body(12, color: AppColors.neutral700),
                      ),
                    ),
                    if (snap.data!.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('لسه معملتش فرق — اضغط "+ فريق"', style: AppText.body(13)),
                      ),
                    for (final t in snap.data!) _row(t),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Team t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Icon(Icons.shield_outlined, size: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(t.name, style: AppText.h(14))),
        Pressable(
          onTap: () => _run(() => _repo.delete(t.id), 'اتحذف ✓'),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
}
