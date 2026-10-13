import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';

/// وقت الماتش عند المدير: هيقفل الساعة كام + فاضل قد إيه (بيتحدّث لوحده) —
/// وأزرار «زوّد ربع ساعة / نص ساعة / ساعة» لو لسه بيلعبوا. الماتش بيتقفل لوحده لما وقته يخلص.
class MatchClockBar extends StatefulWidget {
  const MatchClockBar({super.key, required this.match});
  final GameMatch match;

  @override
  State<MatchClockBar> createState() => _MatchClockBarState();
}

class _MatchClockBarState extends State<MatchClockBar> {
  late int _duration = widget.match.durationMin;
  Timer? _timer;
  bool _busy = false;

  DateTime get _end => widget.match.dateTime.add(Duration(minutes: _duration));

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _extend(int minutes) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final total = await context.read<MatchesRepository>().extendMatch(widget.match.id, minutes);
      if (!mounted) return;
      setState(() => _duration = total);
      messenger.showSnackBar(SnackBar(content: Text('اتزوّد الوقت ✓ — الماتش هيقفل ${arabicTime(_end)}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    if (m.isFinished || !m.timeSet) return const SizedBox.shrink();
    final now = DateTime.now();
    final started = now.isAfter(m.dateTime);
    final left = _end.difference(now).inMinutes;
    final urgent = started && left <= 10;
    final color = urgent ? AppColors.danger : AppColors.accent;
    final line = !started
        ? 'مدة الماتش ${durationLabel(_duration)} — هيقفل لوحده ${arabicTime(_end)}'
        : (left <= 0 ? 'وقت الماتش خلص — بيتقفل دلوقتي' : 'فاضل $left دقيقة — هيقفل لوحده ${arabicTime(_end)}');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(line, style: AppText.h(13, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('زوّد وقت:', style: AppText.body(12, color: AppColors.neutral700)),
              const SizedBox(width: 8),
              for (final (min, label) in const [(15, 'ربع ساعة'), (30, 'نص ساعة'), (60, 'ساعة')])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _extend(min),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text('+ $label'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «ساعة» · «ساعة ونص» · «ساعتين» · «٧٥ دقيقة» …
String durationLabel(int minutes) => switch (minutes) {
  60 => 'ساعة',
  90 => 'ساعة ونص',
  120 => 'ساعتين',
  150 => 'ساعتين ونص',
  180 => '٣ ساعات',
  _ => '$minutes دقيقة',
};

/// اختيار مدة الماتش (الافتراضي ساعة).
class DurationChips extends StatelessWidget {
  const DurationChips({super.key, required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  static const options = [60, 90, 120, 150, 180];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final d in options)
        ChoiceChip(label: Text(durationLabel(d)), selected: value == d, onSelected: (_) => onChanged(d)),
    ],
  );
}
