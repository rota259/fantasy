import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../polls/data/polls_repository.dart';
import '../widgets/manager_poll_results.dart';

/// شاشة المدير: يعمل تحدّي/توقّع بسؤال واختيارات نصّية.
class ManagerChallengeScreen extends StatefulWidget {
  const ManagerChallengeScreen({super.key, required this.pollsRepo});

  final PollsRepository pollsRepo;

  @override
  State<ManagerChallengeScreen> createState() => _ManagerChallengeScreenState();
}

class _ManagerChallengeScreenState extends State<ManagerChallengeScreen> {
  final _question = TextEditingController();
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];

  @override
  void dispose() {
    _question.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    final q = _question.text.trim();
    final opts = _options.map((o) => o.text.trim()).where((o) => o.isNotEmpty).toList();
    if (q.isEmpty || opts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب السؤال واختيارين على الأقل')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await widget.pollsRepo.createChallenge(q, opts);
    messenger.showSnackBar(const SnackBar(content: Text('اتنشر التحدّي ✓')));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'تحدّي الجولة', subtitle: 'MANAGER · CHALLENGE', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ManagerPollResults(kind: 'challenge'),
                Text('اعمل تحدّي جديد — اكتب سؤال أو توقّع، واليوزرز يصوّتوا.',
                    style: AppText.body(12, color: AppColors.neutral700)),
                const SizedBox(height: 12),
                _field(_question, 'السؤال (مثلاً: مين يكسب التجمع ولا أكتوبر؟)'),
                const SizedBox(height: 14),
                Text('الاختيارات', style: AppText.kicker()),
                const SizedBox(height: 8),
                for (var i = 0; i < _options.length; i++) ...[
                  _field(_options[i], 'اختيار ${i + 1}'),
                  const SizedBox(height: 8),
                ],
                GestureDetector(
                  onTap: () => setState(() => _options.add(TextEditingController())),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                    child: Text('+ اختيار', style: AppText.h(13)),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _publish,
                  child: Container(
                    color: AppColors.accent,
                    padding: const EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: Text('انشر التحدّي', style: AppText.h(14, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
      child: TextField(
        controller: c,
        style: AppText.h(14),
        decoration: InputDecoration(
          isDense: true, border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          hintText: hint,
        ),
      ),
    );
  }
}
