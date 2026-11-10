part of 'live_round_screen.dart';

class _LivePoints extends StatelessWidget {
  const _LivePoints({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveRoundCubit, LiveRoundState>(
      builder: (context, s) {
        if (s.status == LiveRoundStatus.loading) {
          return const SkeletonList();
        }
        if (s.status == LiveRoundStatus.error) {
          return Center(
            child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
          );
        }
        final e = s.entry;
        if (e == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'معملتش تشكيلة للجولة دي (${s.window.label})\nاعمل تشكيلة الجولة الجاية من التاب التاني',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.neutral600),
              ),
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            RoundPager(entry: e),
            RoundPointsBody(entry: e, players: s.players, statusFor: s.statusFor, liveTeams: s.liveTeams),
          ],
        );
      },
    );
  }
}
