import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../teams/widgets/team_picker_sheet.dart';

/// شاشة المدير: إنشاء ماتش جديد أو تعديل ماتش (فريقين + معاد). الديدلاين = المعاد − ساعة.
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
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void dispose() {
    _teamA.dispose();
    _teamB.dispose();
    _week.dispose();
    super.dispose();
  }

  Future<void> _pickKickoff() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 1)),
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
      } else {
        await widget.matchesRepo.addMatch(teams: [teamA, teamB], dateTime: _kickoff!, week: week);
      }
      navigator.pop(true);
    } catch (e) {
      setState(() => _saving = false);
      final fallback = _isEdit ? 'تعذّر تعديل الماتش' : 'تعذّر إنشاء الماتش';
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
                GestureDetector(
                  onTap: _pickKickoff,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
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
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    color: AppColors.accent,
                    padding: const EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                          )
                        : Text('احفظ الماتش', style: AppText.h(14, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// المنظّم بيختار من فرقه، والأدمن بيكتب أي اسم.
  Widget _team(TextEditingController c, String hint) {
    final user = context.read<AuthCubit>().state.user;
    if (user == null || !user.isOrganizer) return _field(c, hint);
    return GestureDetector(
      onTap: () async {
        final name = await showTeamPicker(context, user.id);
        if (name != null) setState(() => c.text = name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
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
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
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
