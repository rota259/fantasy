import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../chips/data/chips_repository.dart';
import '../../pick/data/picks_repository.dart';
import '../../players/data/players_repository.dart';
import '../../seasons/data/season.dart';
import '../../seasons/data/seasons_repository.dart';
import '../cubit/my_points_cubit.dart';
import '../data/points_repository.dart';
import '../widgets/round_pager.dart';
import '../widgets/round_points_body.dart';
import '../widgets/season_chips.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// نقطي (من البروفايل): اختار الموسم، واتنقّل بين الجولات — كل جولة لوحدها بتفصيلها.
/// كل جولة نقطها بتبدأ من صفر، والإجمالي = مجموع جولات الموسم (المعتمد) + بونص التوقعات.
class MyPointsScreen extends StatelessWidget {
  const MyPointsScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => MyPointsCubit(
        userId: userId,
        picks: c.read<PicksRepository>(),
        players: c.read<PlayersRepository>(),
        chips: c.read<ChipsRepository>(),
        challenge: c.read<ChallengeRepository>(),
        points: c.read<PointsRepository>(),
        seasons: c.read<SeasonsRepository>(),
      )..load(),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            const StatusArea(),
            Masthead(title: 'نقطي', subtitle: 'MY POINTS', onBack: () => Navigator.pop(context)),
            Expanded(
              child: BlocBuilder<MyPointsCubit, MyPointsState>(
                builder: (context, s) => switch (s.status) {
                  MyPointsStatus.loading => const SkeletonList(),
                  MyPointsStatus.error => Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  ),
                  MyPointsStatus.ready => _SeasonRounds(state: s),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeasonRounds extends StatefulWidget {
  const _SeasonRounds({required this.state});
  final MyPointsState state;

  @override
  State<_SeasonRounds> createState() => _SeasonRoundsState();
}

class _SeasonRoundsState extends State<_SeasonRounds> {
  // الموسم الحالي أول ما تفتح (ولو مفيش: كل المواسم)
  late Season? _season = widget.state.seasons.where((x) => x.isCurrent()).firstOrNull;
  int? _index; // null = آخر جولة

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final rounds = s.roundsIn(_season);
    final bonuses = s.bonusesIn(_season);
    final i = rounds.isEmpty ? -1 : (_index ?? rounds.length - 1).clamp(0, rounds.length - 1);
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        if (s.seasons.isNotEmpty)
          SeasonChips(
            seasons: s.seasons,
            selected: _season,
            onSelect: (x) => setState(() {
              _season = x;
              _index = null;
            }),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_season?.name ?? 'كل المواسم'} · ${rounds.length} جولة${bonuses.isEmpty ? '' : ' + بونص التوقعات'}',
                  style: AppText.body(12, color: AppColors.neutral700),
                ),
              ),
              Text('${s.totalIn(_season)}', style: AppText.h(22, color: AppColors.accent)),
              Text(kTestMode ? ' نقطة' : ' معتمد', style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
        ),
        if (i < 0)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text('معملتش تشكيلة في الموسم ده', style: AppText.body(13, color: AppColors.neutral600)),
            ),
          )
        else ...[
          RoundPager(
            entry: rounds[i],
            number: i + 1,
            onPrev: i > 0 ? () => setState(() => _index = i - 1) : null,
            onNext: i < rounds.length - 1 ? () => setState(() => _index = i + 1) : null,
          ),
          RoundPointsBody(key: ValueKey(rounds[i].window.cutoff), entry: rounds[i], players: s.players),
        ],
        for (final m in bonuses)
          Container(
            margin: AppDecor.tileMargin,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: AppDecor.tile,
            child: Row(
              children: [
                Expanded(child: Text('🎯 فرق أهداف ${m.teamA} ${m.scoreText} ${m.teamB} صح', style: AppText.h(13))),
                Text('+${MyPointsState.predictionBonus}', style: AppText.h(18, color: AppColors.accent)),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
