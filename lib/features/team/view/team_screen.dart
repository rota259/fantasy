import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../pick/view/round_pick_view.dart';
import '../../week/data/week_window.dart';

/// تبويب فريقي — تشكيلة الجولة الحالية (كل لاعب بيتقفل قبل ماتشه بساعة).
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final WeekWindow _open = WeekWindow.open();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    return Column(
      children: [
        const StatusArea(),
        const Masthead(title: 'فريقي · تشكيلة الجولة', subtitle: 'PICK TEAM'),
        Expanded(
          child: user == null
              ? Center(child: Text('سجّل دخولك عشان تختار تشكيلتك', style: AppText.body(13)))
              : RoundPickView(window: _open, userId: user.id, isOrganizer: user.isOrganizer),
        ),
      ],
    );
  }
}
