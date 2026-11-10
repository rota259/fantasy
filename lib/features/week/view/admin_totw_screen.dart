import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/models/totw_candidates.dart';
import '../data/week_repository.dart';
import '../data/week_window.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'admin_totw_screen_sections.dart';

/// (أدمن) تشكيلات الجولة لكل منطقة: النظام بيقترح الأعلى نقط، والأدمن يراجع ويعتمد → تنزل لأهل المنطقة.
class AdminTotwScreen extends StatefulWidget {
  const AdminTotwScreen({super.key});

  @override
  State<AdminTotwScreen> createState() => _AdminTotwScreenState();
}

class _AdminTotwScreenState extends State<AdminTotwScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final WeekRepository _repo = context.read<WeekRepository>();
  WeekWindow _window = WeekWindow.current().previous; // آخر جولة خلصت
  late Future<List<TotwCandidates>> _future = _repo.candidates(_window);
  final _picked = <int, Set<String>>{}; // المنطقة → الخمسة المختارين

  void _load(WeekWindow w) => setState(() {
    _window = w;
    _picked.clear();
    _future = _repo.candidates(w);
  });

  @override
  Widget build(BuildContext context) {
    final canNext = _window.next.isFinal();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'تشكيلات الجولة',
            subtitle: _window.label,
            onBack: () => Navigator.pop(context),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pressable(
                  onTap: () => _load(_window.previous),
                  child: Text('‹  ', style: AppText.h(20, color: AppColors.white)),
                ),
                Pressable(
                  onTap: canNext ? () => _load(_window.next) : null,
                  child: Text('  ›', style: AppText.h(20, color: canNext ? AppColors.white : AppColors.neutral600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TotwCandidates>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                if (snap.data!.isEmpty) {
                  return Center(
                    child: EmptyState(icon: Icons.event_busy_outlined, title: 'مفيش ماتشات في الجولة دي'),
                  );
                }
                return ListView(padding: const EdgeInsets.all(12), children: [for (final z in snap.data!) _zone(z)]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
