import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../data/admin_repository.dart';

/// (مدير) كتابة نتيجة الماتش وإنهاؤه + إشعار لكل اليوزرز.
class MatchResultSection extends StatefulWidget {
  const MatchResultSection({super.key, required this.match});
  final GameMatch match;

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
      await context.read<AdminRepository>().notify(
        title: 'انتهى الماتش 🏁',
        body: '${m.teamA} $a - $b ${m.teamB}',
        kind: 'match',
        matchId: m.id,
      );
      setState(() => _finished = true);
      messenger.showSnackBar(const SnackBar(content: Text('اتسجّلت النتيجة واتبعت إشعار ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل الحفظ: $e')));
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
          'الماتش هيتنقل من "القادمة" للنتايج، واليوزرز هيوصلهم إشعار بالنتيجة.',
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
