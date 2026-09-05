import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/widgets/match_format.dart';

/// شاشة المدير: إنشاء ماتش جديد (فريقين + معاد). الديدلاين = المعاد − ساعة.
class ManagerAddMatchScreen extends StatefulWidget {
  const ManagerAddMatchScreen({super.key, required this.matchesRepo});
  final MatchesRepository matchesRepo;

  @override
  State<ManagerAddMatchScreen> createState() => _ManagerAddMatchScreenState();
}

class _ManagerAddMatchScreenState extends State<ManagerAddMatchScreen> {
  final _teamA = TextEditingController();
  final _teamB = TextEditingController();
  final _week = TextEditingController(text: '1');
  DateTime? _kickoff;
  bool _saving = false;

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
    try {
      await widget.matchesRepo.addMatch(
        teams: [_teamA.text.trim(), _teamB.text.trim()],
        dateTime: _kickoff!,
        week: int.tryParse(_week.text) ?? 1,
      );
      navigator.pop(true);
    } catch (_) {
      setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('تعذّر إنشاء الماتش')));
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
          Masthead(title: 'ماتش جديد', subtitle: 'NEW MATCH', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _field(_teamA, 'الفريق الأول'),
                const SizedBox(height: 10),
                _field(_teamB, 'الفريق التاني'),
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
                  Text('الديدلاين أوتوماتيك: ${arabicTime(k.subtract(const Duration(hours: 1)))} (قبل الماتش بساعة)',
                      style: AppText.body(11, color: AppColors.accent700)),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    color: AppColors.accent,
                    padding: const EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white))
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
