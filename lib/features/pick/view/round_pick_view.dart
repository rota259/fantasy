import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../matches/cubit/live_teams_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../points/widgets/player_round_sheet.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../chips/cubit/chips_cubit.dart';
import '../../chips/data/chip_type.dart';
import '../../chips/data/chips_repository.dart';
import '../../chips/widgets/chips_bar.dart';
import '../../players/data/players_repository.dart';
import '../../teams/data/teams_repository.dart';
import '../../week/data/week_window.dart';
import '../cubit/round_pick_cubit.dart';
import '../data/picks_repository.dart';
import '../widgets/pick_pitch.dart';
import '../widgets/pick_sheets.dart';
import '../widgets/round_pick_bars.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'round_pick_view_sections.dart';

/// تشكيلة الجولة: ٧ من أي فرق في منطقتك + الكروت. مفيش ديدلاين واحد: كل لاعب بيتقفل قبل ماتشه بساعة،
/// وتغيير واحد ببلاش في الجولة والزيادة −٤ (الوايلد كارد: كله ببلاش).
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
        BlocProvider(create: (c) => LiveTeamsCubit(c.read<MatchesRepository>(), window)..load()),
      ],
      child: _View(window: window),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.window});
  final WeekWindow window;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  int? _entry; // بعد الحفظ: اللاعيبة يدخلوا الملعب واحد ورا التاني

  WeekWindow get window => widget.window;

  /// التعديل مسموح طول الجولة — والقفل لكل لاعب لوحده (الكيوبت والسيرفر بيمنعوا اللاعب المتقفل).
  bool get _editable => !window.isFinal();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChipsCubit, ChipsState>(
      buildWhen: (p, c) => p.active != c.active,
      builder: (context, chips) {
        final editable = _editable;
        return Column(
          children: [
            DeadlineBar(window: window, wildcard: chips.active == ChipType.wildcard),
            Expanded(child: _body(context, editable)),
            if (editable) SaveBar(onSave: () => _save(context)),
          ],
        );
      },
    );
  }
}
