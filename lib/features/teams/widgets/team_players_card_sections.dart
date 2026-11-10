part of 'team_players_card.dart';

extension _TeamPlayersCardStateSections1 on _TeamPlayersCardState {
  Future<void> _load() async {
    try {
      final list = await _repo.fetchByTeams([widget.team.name]);
      list.sort((a, b) {
        final g = (a.position == 'GK' ? 0 : 1).compareTo(b.position == 'GK' ? 0 : 1);
        return g != 0 ? g : a.name.compareTo(b.name);
      });
      if (mounted) _update(() => _players = list);
    } catch (_) {
      if (mounted) _update(() => _players ??= const []);
    }
  }

  Future<void> _add() async {
    final r = await showAddTeamPlayerSheet(context, widget.team.name);
    if (r == null || !mounted) return;
    _update(() => _busy = true);
    try {
      final id = await _repo.addPlayer(
        name: r.name,
        team: widget.team.name,
        position: r.position,
        nickname: r.nickname,
      );
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
      if (mounted) _update(() => _busy = false);
    }
  }

  Future<void> _photo(Player p) async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (f == null || !mounted) return;
    _update(() => _busy = true);
    try {
      await _repo.uploadPhoto(p.id, await f.readAsBytes(), f.name.contains('.') ? f.name.split('.').last : 'jpg');
      await _load();
      if (mounted) _snack('اتحدّثت صورة ${p.name} ✓');
    } catch (e) {
      if (mounted) _snack(dbMessage(e, fallback: 'الصورة ماترفعتش'));
    } finally {
      if (mounted) _update(() => _busy = false);
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
