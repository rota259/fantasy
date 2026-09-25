import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/availability.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../players/widgets/availability_badge.dart';
import '../cubit/manager_players_cubit.dart';

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
            Masthead(title: 'حالة اللاعيبة', subtitle: 'MANAGER · STATUS', onBack: () => Navigator.pop(context)),
            Expanded(
              child: BlocBuilder<ManagerPlayersCubit, ManagerPlayersState>(
                builder: (context, s) {
                  if (s.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }
                  if (s.players.isEmpty) {
                    return Center(
                      child: Text('ضيف لاعيبة الأول', style: AppText.body(13, color: AppColors.neutral600)),
                    );
                  }
                  final cubit = context.read<ManagerPlayersCubit>();
                  return ListView(
                    padding: EdgeInsets.zero,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _editSheet(context, cubit, p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
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
  late String _status = widget.player.availability;
  late final TextEditingController _reason = TextEditingController(text: widget.player.news ?? '');

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reasons = Availability.reasons(_status);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.player.name, style: AppText.h(16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in Availability.all)
                    GestureDetector(
                      onTap: () => setState(() => _status = a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _status == a ? AppColors.accent : null,
                          border: Border.all(color: _status == a ? AppColors.accent : AppColors.black, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Availability.icon(a),
                              size: 14,
                              color: _status == a ? AppColors.white : Availability.color(a),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              Availability.label(a),
                              style: AppText.h(12, color: _status == a ? AppColors.white : AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('ترشيحات السبب', style: AppText.kicker()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in reasons)
                      GestureDetector(
                        onTap: () => setState(() => _reason.text = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
                          child: Text(r, style: AppText.body(11)),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                child: TextField(
                  controller: _reason,
                  style: AppText.h(13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'السبب/التفاصيل (اختياري)',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  final news = _status == Availability.ready ? null : _reason.text.trim();
                  widget.cubit.setAvailability(widget.player.id, _status, news);
                  Navigator.pop(context);
                },
                child: Container(
                  color: AppColors.accent,
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text('احفظ الحالة', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
