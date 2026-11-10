import 'package:flutter/material.dart';
import '../widgets/match_clock_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../teams/widgets/team_picker_sheet.dart';
import '../../week/data/week_window.dart';
import '../../../core/widgets/motion.dart';

part 'manager_add_match_screen_sections.dart';
part 'manager_add_match_screen_sections2.dart';

/// شاشة المدير: إنشاء ماتش جديد أو تعديل ماتش (فريقين + معاد). الديدلاين = المعاد − ساعة.
/// لو ديدلاين الجولة عدّى: الأدمن بيضيف عادي، ومدير المنطقة بيبعت طلب للإدارة.
class ManagerAddMatchScreen extends StatefulWidget {
  const ManagerAddMatchScreen({super.key, required this.matchesRepo, this.editing});
  final MatchesRepository matchesRepo;
  final GameMatch? editing; // لو موجود = وضع التعديل

  @override
  State<ManagerAddMatchScreen> createState() => _ManagerAddMatchScreenState();
}

class _ManagerAddMatchScreenState extends State<ManagerAddMatchScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final _teamA = TextEditingController(text: widget.editing?.teamA ?? '');
  late final _teamB = TextEditingController(text: widget.editing?.teamB ?? '');
  late final _week = TextEditingController(text: '${widget.editing?.week ?? 1}');
  late DateTime? _kickoff = widget.editing?.dateTime;
  late int _duration = widget.editing?.durationMin ?? 60;
  bool _saving = false;

  bool get _isEdit => widget.editing != null;
  bool get _isAdmin => !(context.read<AuthCubit>().state.user?.isOrganizer ?? false);

  @override
  void dispose() {
    _teamA.dispose();
    _teamB.dispose();
    _week.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
