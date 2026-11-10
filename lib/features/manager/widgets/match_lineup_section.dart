import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/selection_bar.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../cubit/manager_match_cubit.dart';
import 'add_team_player_sheet.dart';
import 'team_lineup_pitch.dart';

part 'match_lineup_section_parts.dart';
part 'match_lineup_section_parts2.dart';

/// (مدير) تاب التشكيلة: خماسي ولا سداسي، وكل فريق على ملعبه (الأول فوق والتاني تحت).
/// دوس على مكان فاضي تختار لاعب، ودوس على لاعب تنقله احتياطي/أساسي أو تشيله أو تحذفه من الفريق.
class MatchLineupSection extends StatelessWidget {
  const MatchLineupSection({super.key, required this.match, required this.cubit, required this.state});

  final GameMatch match;
  final ManagerMatchCubit cubit;
  final ManagerMatchState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('الملعب', style: AppText.h(15))),
            _format(5, 'خماسي'),
            const SizedBox(width: 6),
            _format(6, 'سداسي'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'كل فريق: ${state.format} أساسيين (حارس + ${state.format - 1}) والاحتياطي اختياري — الفريق آخره ٧.',
          style: AppText.body(11, color: AppColors.neutral700),
        ),
        const SizedBox(height: 12),
        _team(context, match.teamA),
        const SizedBox(height: 18),
        _team(context, match.teamB),
        const SizedBox(height: 20),
        _button('احفظ التشكيلة', filled: true, onTap: () => _run(context, cubit.saveLineup)),
        const SizedBox(height: 10),
        _button('أبلغ اليوزرز إن التشكيلة نزلت', onTap: () => _run(context, cubit.notifyUsers)),
      ],
    );
  }
}
