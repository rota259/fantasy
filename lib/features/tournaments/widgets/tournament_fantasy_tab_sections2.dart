part of 'tournament_fantasy_tab.dart';

extension _TournamentFantasyTabStateSections2 on _TournamentFantasyTabState {
  Widget _token(FantasyPlayer p, bool open) {
    final cap = p.id == _captain;
    return Pressable(
      onTap: open ? () => _update(() => _captain = p.id) : null,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Jersey(
              label: p.name.characters.take(2).toString(),
              size: 46,
              style: cap ? JerseyStyle.gold : (p.gk ? JerseyStyle.keeper : JerseyStyle.white),
              phase: (p.id.hashCode % 100) / 100,
            ),
            const SizedBox(height: 3),
            Text(
              '${cap ? '© ' : ''}${p.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(10, color: cap ? AppColors.gold : AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(FantasyPlayer p, bool open) {
    final on = _sel.contains(p.id);
    final url = p.imageUrl;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: open ? () => _toggle(p) : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent100 : null,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.neutral200,
              child: url == null || url.isEmpty
                  ? Text(p.name.characters.take(2).toString(), style: AppText.h(11))
                  : ClipOval(child: NetImage(url, width: 34, height: 34)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${p.name}${p.gk ? ' 🧤' : ''}', style: AppText.h(13))),
            Text('${p.points} ن', style: AppText.body(12, color: AppColors.neutral700)),
            const SizedBox(width: 8),
            Icon(
              on ? Icons.check_circle : Icons.add_circle_outline,
              size: 20,
              color: on ? AppColors.accent : AppColors.neutral500,
            ),
          ],
        ),
      ),
    );
  }
}
