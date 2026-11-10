part of 'player_fan_screen.dart';

extension _PlayerFanScreenStateSections1 on _PlayerFanScreenState {
  /// كارت story للاعب الحقيقي: صورته (أو تيشيرته) + «كام واحد خلّاني كابتن» بالرقم الكبير + أرقامه.
  Widget _card(FanStats s) {
    final refCode = context.read<AuthCubit>().state.user?.refCode;
    final cap = s.captains > 0;
    final url = p.imageUrl;
    return StoryFrame(
      kicker: _window.label,
      refCode: refCode,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (url == null || url.isEmpty)
            Jersey(label: p.initials, size: 112)
          else
            PhotoCard(
              url: url,
              width: 104,
              frame: StoryColors.lime,
              fallback: Text(p.initials, style: AppText.h(30, color: Colors.white)),
            ),
          const SizedBox(height: 10),
          Text(
            p.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.h(26, color: Colors.white),
          ),
          Text('${p.team} · ${p.positionAr}', style: AppText.body(12, color: Colors.white60)),
          const SizedBox(height: 10),
          Text('${cap ? s.captains : s.owners}', style: AppText.h(104, color: StoryColors.lime, height: 1)),
          Text(
            cap ? 'انا الكابتن بتاعهم الجوله دي' : 'اختاروني في تشكيلتهم',
            style: AppText.h(18, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StoryTile(label: 'اختاروني', value: '${s.owners}', big: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StoryTile(label: 'الامتلاك', value: '${s.ownership.toStringAsFixed(0)}%', big: true),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StoryTile(
                  label: 'نقط جبتهالهم',
                  value: '${s.pointsForUsers}',
                  big: true,
                  accent: StoryColors.gold,
                ),
              ),
            ],
          ),
          if (s.posTotal > 0) ...[
            const SizedBox(height: 12),
            StoryPill(
              '#${s.posRank} بين ${p.position == 'GK' ? 'الحراس' : 'اللاعيبة'} من ${s.posTotal}',
              icon: Icons.leaderboard_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
