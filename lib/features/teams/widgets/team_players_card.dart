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
  late final PlayersRepository _repo = context.read<PlayersRepository>();
  late bool _open = widget.initiallyOpen;
  List<Player>? _players;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.fetchByTeams([widget.team.name]);
      list.sort((a, b) {
        final g = (a.position == 'GK' ? 0 : 1).compareTo(b.position == 'GK' ? 0 : 1);
        return g != 0 ? g : a.name.compareTo(b.name);
      });
      if (mounted) setState(() => _players = list);
    } catch (_) {
      if (mounted) setState(() => _players ??= const []);
    }
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _add() async {
    final r = await showAddTeamPlayerSheet(context, widget.team.name);
    if (r == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final id = await _repo.addPlayer(name: r.name, team: widget.team.name, position: r.position);
      var note = '';
      if (r.photo != null) {
        try {
          await _repo.uploadPhoto(id, r.photo!, r.photoExt ?? 'jpg');
        } catch (_) {
          note = ' — بس الصورة ماترفعتش، جرّب تضيفها تاني';
        }
      }
      await _load();
      if (mounted) _snack('اتضاف «${r.name}» ✓$note');
    } catch (e) {
      if (mounted) _snack(dbMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _photo(Player p) async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (f == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repo.uploadPhoto(p.id, await f.readAsBytes(), f.name.contains('.') ? f.name.split('.').last : 'jpg');
      await _load();
      if (mounted) _snack('اتحدّثت صورة ${p.name} ✓');
    } catch (e) {
      if (mounted) _snack(dbMessage(e, fallback: 'الصورة ماترفعتش'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف اللاعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «${p.name}»؟', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final n = await _repo.deletePlayers([p.id]);
      await _load();
      if (mounted) _snack(n == 0 ? 'اللاعب ده لعب واتسجّل له أحداث — كلّم الإدارة' : 'اتحذف «${p.name}» ✓');
    } catch (e) {
      if (mounted) _snack(dbMessage(e));
    }
  }

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

  Widget _row(Player p) {
    final url = p.imageUrl;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: AppDecor.softDivider,
      child: Row(
        children: [
          // الصورة — الضغط بيغيّرها
          Pressable(
            onTap: _busy ? null : () => _photo(p),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.accent100,
                  child: url == null || url.isEmpty
                      ? Text(p.initials, style: AppText.h(12, color: AppColors.accent700))
                      : ClipOval(child: NetImage(url, width: 42, height: 42)),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.photo_camera, size: 10, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.name}${p.position == 'GK' ? ' 🧤' : ''}', style: AppText.h(13)),
                Text(p.positionAr, style: AppText.body(11, color: AppColors.neutral700)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'احذف اللاعب',
            onPressed: _busy ? null : () => _delete(p),
            icon: Icon(Icons.close, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
