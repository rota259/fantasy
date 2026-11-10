import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/availability.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../players/widgets/availability_badge.dart';
import '../cubit/manager_players_cubit.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'manager_availability_screen_sections.dart';

/// شاشة المدير: حالة اللاعيبة (جاهز/مصاب/…) وسببها.
class ManagerAvailabilityScreen extends StatelessWidget {
  const ManagerAvailabilityScreen({super.key, required this.playersRepo});

  final PlayersRepository playersRepo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerPlayersCubit(playersRepo)..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(title: 'حالة اللاعيبة', subtitle: 'ADMIN · STATUS', onBack: () => Navigator.pop(context)),
            Expanded(
              child: BlocBuilder<ManagerPlayersCubit, ManagerPlayersState>(
                builder: (context, s) {
                  if (s.isLoading) {
                    return const SkeletonList();
                  }
                  if (s.players.isEmpty) {
                    return Center(
                      child: Text('ضيف لاعيبة الأول', style: AppText.body(13, color: AppColors.neutral600)),
                    );
                  }
                  final cubit = context.read<ManagerPlayersCubit>();
                  return ListView(
                    padding: const EdgeInsets.only(top: 14, bottom: 24),
                    children: [for (final p in s.players) _row(context, cubit, p)],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, ManagerPlayersCubit cubit, Player p) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => _editSheet(context, cubit, p),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            AvailabilityBadge(p.availability, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: AppText.h(14)),
                  Text(
                    p.news?.isNotEmpty == true
                        ? '${Availability.statusLine(p.availability)} · ${p.news}'
                        : Availability.statusLine(p.availability),
                    style: AppText.body(10, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            Text('عدّل ›', style: AppText.h(12, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }

  void _editSheet(BuildContext context, ManagerPlayersCubit cubit, Player p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(cubit: cubit, player: p),
    );
  }
}

class _StatusSheet extends StatefulWidget {
  const _StatusSheet({required this.cubit, required this.player});
  final ManagerPlayersCubit cubit;
  final Player player;

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late String _status = widget.player.availability;
  late final TextEditingController _reason = TextEditingController(text: widget.player.news ?? '');

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
