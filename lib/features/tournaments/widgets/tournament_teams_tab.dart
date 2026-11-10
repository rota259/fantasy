import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../cubit/tournament_cubit.dart';
import 'draw_animation.dart';
import 'register_team_sheet.dart';

part 'tournament_teams_tab_sections.dart';

/// الفرق: المقبولين (بمجموعاتهم) · الطلبات (للمنظّم) · ضيف فريق · القرعة — واليوزر يسجّل فريقه.
class TournamentTeamsTab extends StatefulWidget {
  const TournamentTeamsTab({super.key, required this.state, required this.runs});
  final TournamentState state;
  final bool runs; // أنا اللي بدير البطولة

  @override
  State<TournamentTeamsTab> createState() => _TournamentTeamsTabState();
}

class _TournamentTeamsTabState extends State<TournamentTeamsTab> {
  final _team = TextEditingController();

  @override
  void dispose() {
    _team.dispose();
    super.dispose();
  }

  void _msg(String? err, String ok) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? ok)));

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
