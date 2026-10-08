import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/confetti.dart';

/// القرعة متحركة: كورة ورا كورة بتنزل بالفريق في مجموعته (أو في مكانه في الشجرة).
/// [columns]: اسم العمود (مجموعة A · الشجرة · الدوري) ← الفرق بالترتيب.
Future<void> showDrawAnimation(BuildContext context, Map<String, List<String>> columns) => showGeneralDialog(
  context: context,
  barrierDismissible: false,
  barrierColor: Colors.black.withValues(alpha: 0.9),
  pageBuilder: (_, _, _) => _Draw(columns: columns),
);

class _Draw extends StatefulWidget {
  const _Draw({required this.columns});
  final Map<String, List<String>> columns;

  @override
  State<_Draw> createState() => _DrawState();
}

class _DrawState extends State<_Draw> {
  late final List<(String, String)> _order = [
    // بالتبادل بين المجموعات زي القرعة الحقيقية
    for (var i = 0; i < widget.columns.values.fold(0, (m, l) => l.length > m ? l.length : m); i++)
      for (final e in widget.columns.entries)
        if (i < e.value.length) (e.key, e.value[i]),
  ];
  int _n = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 650), (_) {
      if (_n >= _order.length) return _t?.cancel();
      HapticFeedback.selectionClick();
      setState(() => _n++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _order.take(_n).toList();
    final done = _n >= _order.length;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            if (done) const Positioned.fill(child: ConfettiBurst(count: 60)),
            Column(
              children: [
                const SizedBox(height: 20),
                Text('🎲 القرعة', style: AppText.h(28, color: Colors.white)),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final col in widget.columns.keys)
                          Container(
                            width: 150,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Text(col, style: AppText.h(14, color: const Color(0xFFF2C14E))),
                                const SizedBox(height: 8),
                                for (final x in shown.where((x) => x.$1 == col)) _ball(x.$2),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: () => done ? Navigator.pop(context) : setState(() => _n = _order.length),
                    child: Text(done ? 'تمام — شوف الجدول' : 'تخطّي'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ball(String team) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 600),
    curve: Curves.elasticOut,
    builder: (_, s, c) => Transform.scale(scale: s, child: c),
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Text('⚽'),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              team,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(12, color: Colors.black),
            ),
          ),
        ],
      ),
    ),
  );
}
