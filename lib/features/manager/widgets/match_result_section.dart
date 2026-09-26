import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/supabase/db_error.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';

/// كتابة نتيجة الماتش وإنهاؤه — السيرفر بيبعت إشعار النتيجة، ولو منظّم بيبدأ تأكيد اللاعيبة.
class MatchResultSection extends StatefulWidget {
  const MatchResultSection({super.key, required this.match, required this.isAdmin});
  final GameMatch match;
  final bool isAdmin;

  @override
  State<MatchResultSection> createState() => _MatchResultSectionState();
}

class _MatchResultSectionState extends State<MatchResultSection> {
  late final _a = TextEditingController(text: widget.match.scoreA?.toString() ?? '');
  late final _b = TextEditingController(text: widget.match.scoreB?.toString() ?? '');
  late bool _finished = widget.match.isFinished;
  bool _saving = false;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final a = int.tryParse(_a.text.trim());
    final b = int.tryParse(_b.text.trim());
    final messenger = ScaffoldMessenger.of(context);
    if (a == null || b == null || a < 0 || b < 0) {
      messenger.showSnackBar(const SnackBar(content: Text('اكتب أهداف الفريقين')));
      return;
    }
    final m = widget.match;
    setState(() => _saving = true);
    try {
      await context.read<MatchesRepository>().finishMatch(m.id, a, b);
      if (!mounted) return;
      final first = !_finished;
      setState(() => _finished = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            !first
                ? 'اتحدّثت النتيجة ✓'
                : widget.isAdmin
                ? 'اتسجّلت النتيجة واتبعت إشعار ✓'
                : 'اتسجّلت النتيجة ✓ — لاعيبة الفريقين هيوصلهم طلب تأكيد',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'فشل الحفظ'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_finished ? 'الماتش خلص ✓ — تقدر تعدّل النتيجة' : 'اكتب النتيجة وقفّل الماتش', style: AppText.h(15)),
        const SizedBox(height: 4),
        Text(
          widget.isAdmin
              ? 'الماتش هيتنقل من "القادمة" للنتايج، واليوزرز هيوصلهم إشعار بالنتيجة.'
              : 'بعد الإنهاء: لاعيبة الفريقين يأكدوا الورقة، ولو محدش اعترض خلال ١٢ ساعة النقط بتتعتمد. '
                    'أي تعديل بعد الإنهاء بيلغي التأكيدات ويبدأ المدة من الأول.',
          style: AppText.body(11, color: AppColors.neutral700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _goals(m.teamA, _a)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('-', style: AppText.h(28)),
            ),
            Expanded(child: _goals(m.teamB, _b)),
          ],
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _saving ? null : _finish,
          child: Container(
            color: _saving ? AppColors.neutral500 : AppColors.accent,
            padding: const EdgeInsets.all(13),
            alignment: Alignment.center,
            child: Text(
              _finished ? 'حدّث النتيجة' : '🏁 إنهاء الماتش وإعلان النتيجة',
              style: AppText.h(14, color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _goals(String team, TextEditingController c) {
    return Column(
      children: [
        Text(
          team,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.h(13, color: AppColors.accent),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppText.h(30),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              hintText: '0',
            ),
          ),
        ),
      ],
    );
  }
}
