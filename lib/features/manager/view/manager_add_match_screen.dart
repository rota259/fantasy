import 'package:flutter/material.dart';
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
import '../widgets/late_match_notice.dart';
import '../../../core/widgets/motion.dart';

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
  late final _teamA = TextEditingController(text: widget.editing?.teamA ?? '');
  late final _teamB = TextEditingController(text: widget.editing?.teamB ?? '');
  late final _week = TextEditingController(text: '${widget.editing?.week ?? 1}');
  late DateTime? _kickoff = widget.editing?.dateTime;
  final _note = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.editing != null;
  bool get _isAdmin => !(context.read<AuthCubit>().state.user?.isOrganizer ?? false);

  /// ميعاد في جولة تشكيلاتها اتقفلت.
  bool get _late {
    final k = _kickoff;
    return k != null && !_isEdit && WeekWindow.current(k).isLocked();
  }

  /// مدير المنطقة + الديدلاين عدّى = طلب للإدارة بدل الحفظ.
  bool get _asRequest => _late && !_isAdmin;

  @override
  void dispose() {
    _teamA.dispose();
    _teamB.dispose();
    _week.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickKickoff() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: _isAdmin ? 14 : 1)), // الأدمن يضيف ماتش اتلعب في الجولة
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _kickoff = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_teamA.text.trim().isEmpty || _teamB.text.trim().isEmpty || _kickoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الفريقين واختر المعاد')));
      return;
    }
    if (WeekWindow.inGap(_kickoff!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مفيش ماتشات السبت من ٨ الصبح لـ ٤ العصر (بين الجولتين)')));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final teamA = _teamA.text.trim();
    final teamB = _teamB.text.trim();
    final week = int.tryParse(_week.text) ?? 1;
    try {
      if (_isEdit) {
        await widget.matchesRepo.updateMatch(
          widget.editing!.id,
          teams: [teamA, teamB],
          dateTime: _kickoff!,
          week: week,
        );
      } else if (_asRequest) {
        await widget.matchesRepo.requestLateMatch(teams: [teamA, teamB], dateTime: _kickoff!, note: _note.text);
        messenger.showSnackBar(const SnackBar(content: Text('الطلب اتبعت للإدارة — هيوصلك إشعار بالرد')));
        navigator.pop(false);
        return;
      } else {
        await widget.matchesRepo.addMatch(teams: [teamA, teamB], dateTime: _kickoff!, week: week);
      }
      navigator.pop(true);
    } catch (e) {
      setState(() => _saving = false);
      final fallback = _isEdit ? 'تعذّر تعديل الماتش' : (_asRequest ? 'تعذّر بعت الطلب' : 'تعذّر إنشاء الماتش');
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: fallback))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = _kickoff;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: _isEdit ? 'تعديل ماتش' : 'ماتش جديد',
            subtitle: _isEdit ? 'EDIT MATCH' : 'NEW MATCH',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _team(_teamA, 'الفريق الأول'),
                const SizedBox(height: 10),
                _team(_teamB, 'الفريق التاني'),
                const SizedBox(height: 10),
                _field(_week, 'رقم الجولة', number: true),
                const SizedBox(height: 12),
                Pressable(
                  onTap: _pickKickoff,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Text(
                      k == null ? 'اختر معاد الماتش' : 'المعاد: ${arabicWeekday(k)} ${arabicTime(k)}',
                      style: AppText.h(13, color: k == null ? AppColors.neutral600 : AppColors.ink),
                    ),
                  ),
                ),
                if (k != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'الديدلاين أوتوماتيك: ${arabicTime(k.subtract(const Duration(hours: 1)))} (قبل الماتش بساعة)',
                    style: AppText.body(11, color: AppColors.accent700),
                  ),
                ],
                if (_late) ...[const SizedBox(height: 12), LateMatchNotice(isAdmin: _isAdmin, note: _note)],
                const SizedBox(height: 16),
                Pressable(
                  onTap: _saving ? null : _save,
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                    padding: const EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                          )
                        : Text(
                            _asRequest ? 'ابعت طلب للإدارة' : 'احفظ الماتش',
                            style: AppText.h(14, color: AppColors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// المدير بيختار من فرقه، والأدمن بيكتب أي اسم.
  Widget _team(TextEditingController c, String hint) {
    final user = context.read<AuthCubit>().state.user;
    if (user == null || !user.isOrganizer) return _field(c, hint);
    return Pressable(
      onTap: () async {
        final name = await showTeamPicker(context, user.id);
        if (name != null) setState(() => c.text = name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                c.text.isEmpty ? '$hint (من فرقك)' : c.text,
                style: AppText.h(14, color: c.text.isEmpty ? AppColors.neutral600 : AppColors.ink),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: AppText.h(14),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          hintText: hint,
        ),
      ),
    );
  }
}
