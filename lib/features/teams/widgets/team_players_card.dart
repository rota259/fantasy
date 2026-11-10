import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/net_image.dart';
import '../../manager/widgets/add_team_player_sheet.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/team.dart';

part 'team_players_card_sections.dart';

/// فريق من فرقي وتحته لاعيبته: ضيف لاعب (بصورته) · غيّر صورة لاعب · احذف لاعب · احذف الفريق.
class TeamPlayersCard extends StatefulWidget {
  const TeamPlayersCard({super.key, required this.team, required this.onDeleteTeam, this.initiallyOpen = false});
  final Team team;
  final VoidCallback onDeleteTeam;
  final bool initiallyOpen;

  @override
  State<TeamPlayersCard> createState() => _TeamPlayersCardState();
}

class _TeamPlayersCardState extends State<TeamPlayersCard> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final PlayersRepository _repo = context.read<PlayersRepository>();
  late bool _open = widget.initiallyOpen;
  List<Player>? _players;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final players = _players;
    return Container(
      margin: AppDecor.tileMargin,
      decoration: AppDecor.tile,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 20, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(widget.team.name, style: AppText.h(15))),
                  Text(
                    players == null ? '…' : '${players.length} لاعب',
                    style: AppText.body(12, color: AppColors.neutral700),
                  ),
                  AnimatedRotation(turns: _open ? 0.5 : 0, duration: Motion.fast, child: const Icon(Icons.expand_more)),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.medium,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_busy) const LinearProgressIndicator(minHeight: 2),
                      for (final p in players ?? const <Player>[]) _row(p),
                      if (players != null && players.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                          child: Text(
                            'لسه مفيش لاعيبة في الفريق ده',
                            style: AppText.body(12, color: AppColors.neutral600),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _busy ? null : _add,
                                icon: const Icon(Icons.person_add_alt_1, size: 18),
                                label: const Text('ضيف لاعب'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'احذف الفريق (لو فاضي)',
                              onPressed: widget.onDeleteTeam,
                              icon: Icon(Icons.delete_outline, color: AppColors.danger),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
