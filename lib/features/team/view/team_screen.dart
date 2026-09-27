import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../pick/view/round_pick_view.dart';
import '../../week/data/week_window.dart';
import '../../../core/widgets/motion.dart';

/// تبويب فريقي — تشكيلة الجولة الجاية.
/// بين ديدلاين السبت ٣ العصر وبداية الجولة ٤ العصر: الجولة الجاية متقفلة (إلا بالوايلد كارد)
/// فبيظهر اختيار كمان للجولة اللي بعدها.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final WeekWindow _upcoming = WeekWindow.live().next; // أقرب جولة لسه مبدأتش
  late final WeekWindow _open = WeekWindow.open();
  late WeekWindow _shown = _open;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    return Column(
      children: [
        const StatusArea(),
        const Masthead(title: 'فريقي · تشكيلة الجولة', subtitle: 'PICK TEAM'),
        // بين الديدلاين (السبت ٣) والبداية (٤): الجاية متقفلة → اختيار كمان للي بعدها
        if (_open.cutoff.isAfter(_upcoming.cutoff))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [_tab('الجولة الجاية 🔒', _upcoming), const SizedBox(width: 6), _tab('اللي بعدها', _open)],
            ),
          ),
        Expanded(
          child: user == null
              ? Center(child: Text('سجّل دخولك عشان تختار تشكيلتك', style: AppText.body(13)))
              : RoundPickView(window: _shown, userId: user.id, isOrganizer: user.isOrganizer),
        ),
      ],
    );
  }

  Widget _tab(String label, WeekWindow w) {
    final on = _shown == w;
    return Expanded(
      child: Pressable(
        onTap: () => setState(() => _shown = w),
        child: Container(
          padding: const EdgeInsets.all(9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            color: on ? AppColors.accent : null,
            border: Border.all(color: on ? AppColors.accent : AppColors.black, width: 2),
          ),
          child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
        ),
      ),
    );
  }
}
