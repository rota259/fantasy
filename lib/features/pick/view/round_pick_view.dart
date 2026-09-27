import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../chips/cubit/chips_cubit.dart';
import '../../chips/data/chip_type.dart';
import '../../chips/data/chips_repository.dart';
import '../../chips/widgets/chips_bar.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/players_repository.dart';
import '../../teams/data/teams_repository.dart';
import '../../week/data/week_window.dart';
import '../cubit/round_pick_cubit.dart';
import '../data/picks_repository.dart';
import '../widgets/pick_pitch.dart';
import '../widgets/pick_sheets.dart';
import '../widgets/round_pick_bars.dart';

/// تشكيلة الجولة: ٧ من أي فرق في منطقتك + الكروت. بتتقفل السبت ٣ العصر (والوايلد كارد لحد ٤ العصر).
class RoundPickView extends StatelessWidget {
  const RoundPickView({super.key, required this.window, required this.userId, this.isOrganizer = false});

  final WeekWindow window;
  final String userId;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      key: ValueKey(window),
      providers: [
        BlocProvider(
          create: (c) => RoundPickCubit(
            c.read<PlayersRepository>(),
            c.read<PicksRepository>(),
            c.read<TeamsRepository>(),
            window,
            userId,
            isOrganizer: isOrganizer,
          )..load(),
        ),
        BlocProvider(create: (c) => ChipsCubit(c.read<ChipsRepository>(), window.cutoff)..load()),
      ],
      child: _View(window: window),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.window});
  final WeekWindow window;

  /// التعديل مسموح قبل الديدلاين، أو بالوايلد كارد لحد ما الجولة تبدأ.
  /// (في وضع التجربة الديدلاين = نهاية الجولة، فالتشكيلة مفتوحة حتى والجولة شغّالة)
  bool _editable(ChipType? chip) => !window.isLocked() || (chip == ChipType.wildcard && !window.hasStarted());

  Future<void> _save(BuildContext context, bool wildcard) async {
    final messenger = ScaffoldMessenger.of(context);
    final chips = context.read<ChipsCubit>();
    final err = await context.read<RoundPickCubit>().save(wildcard: wildcard);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتحفظت تشكيلة الجولة ✓ — تقدر تفعّل كارت دلوقتي لو عايز'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
        duration: Duration(milliseconds: err == null ? 2200 : 4000),
      ),
    );
    if (err == null) chips.load(); // الكروت بتحتاج تشكيلة محفوظة
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChipsCubit, ChipsState>(
      buildWhen: (p, c) => p.active != c.active,
      builder: (context, chips) {
        final editable = _editable(chips.active);
        return Column(
          children: [
            DeadlineBar(window: window, wildcard: chips.active == ChipType.wildcard),
            Expanded(child: _body(context, editable)),
            if (editable) SaveBar(onSave: () => _save(context, chips.active == ChipType.wildcard)),
          ],
        );
      },
    );
  }

  Widget _body(BuildContext context, bool editable) {
    return BlocBuilder<RoundPickCubit, RoundPickState>(
      builder: (context, s) {
        if (s.isLoading) return Center(child: CircularProgressIndicator(color: AppColors.accent));
        if (s.players.isEmpty) {
          return _note('لسه مفيش لاعيبة في منطقتك — المديرين بينزّلوا فرقهم وماتشاتهم قبل السبت ٣ العصر');
        }
        final cubit = context.read<RoundPickCubit>();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            PickCounts(state: s),
            if (s.fromLastRound && editable)
              PickBanner(
                text: 'دي تشكيلتك من الجولة اللي فاتت — احفظها عشان تتحسب في الجولة دي',
                color: AppColors.info,
              ),
            if (!s.saved && !editable) PickBanner(text: 'معملتش تشكيلة للجولة دي', color: AppColors.neutral600),
            PickPitch(
              state: s,
              onSlotTap: editable ? (kind) => showAddPlayerSheet(context, cubit, s, kind) : (_) {},
              onPlayerTap: editable ? (p) => showPlayerOptionsSheet(context, cubit, s, p) : (_) {},
            ),
            const ChipsBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Text(
                'القواعد: ٧ لاعيبة من أي فرق في منطقتك — ٥ أساسي (حارس واحد) + ٢ احتياطي.\n'
                'لازم كابتن (×٢) وكابتن بديل (بياخد المضاعفة لو الكابتن ملعبش ولا ماتش في الجولة).\n'
                'نقط كل لاعب = كل اللي عمله في ماتشات الجولة. الديدلاين ${arabicWeekday(window.deadline)} '
                '${arabicTime(window.deadline)}.',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _note(String t) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Text(
        t,
        textAlign: TextAlign.center,
        style: AppText.body(13, color: AppColors.neutral600),
      ),
    ),
  );
}
