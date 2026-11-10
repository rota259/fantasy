import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/share/story_parts.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/confetti.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../week/data/week_window.dart';
import '../data/points_repository.dart';
import '../data/round_recap.dart';
import '../widgets/round_story_card.dart';
import '../widgets/wrapped_slide.dart';

part 'round_wrapped_screen_sections.dart';

/// «جولتك في ٥ سلايدز» زي Spotify Wrapped: نقطك · أحسن اختيار · الكابتن · ترتيبك · كارت للشير.
/// بيتقلب لوحده كل ٥ ثواني، والضغط يمين/شمال بيقدّم/يرجّع.
class RoundWrappedScreen extends StatefulWidget {
  const RoundWrappedScreen({super.key, required this.window});
  final WeekWindow window;

  static Future<void> open(BuildContext context, WeekWindow w) => Navigator.of(
    context,
  ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => RoundWrappedScreen(window: w)));

  @override
  State<RoundWrappedScreen> createState() => _RoundWrappedScreenState();
}

class _RoundWrappedScreenState extends State<RoundWrappedScreen> with SingleTickerProviderStateMixin {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  static const _slides = 5;
  late final AnimationController _bar = AnimationController(vsync: this, duration: const Duration(seconds: 5))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _go(1);
    });
  late final Future<RoundRecap> _recap = context.read<PointsRepository>().roundRecap(widget.window.cutoff);
  final _cardKey = GlobalKey();
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _bar.forward();
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  WrappedTone get _tone => WrappedTone.all[_i];

  @override
  Widget build(BuildContext context) {
    final tone = _tone;
    return Scaffold(
      backgroundColor: tone.colors.last,
      body: Stack(
        children: [
          // خلفية السلايد (بتتبدّل بنعومة مع كل سلايد)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: StoryBackdrop(
                key: ValueKey(_i),
                colors: tone.colors,
                line: tone.fg,
                glow: tone.fg == Colors.white ? tone.accent : Colors.white,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<RoundRecap>(
              future: _recap,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(14, color: Colors.white)),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: StoryColors.lime));
                final r = snap.data!;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // RTL: الضغط على الشمال = اللي بعده
                  onTapUp: (d) => _go(d.localPosition.dx < MediaQuery.sizeOf(context).width / 2 ? 1 : -1),
                  child: Column(
                    children: [
                      _progress(tone.fg),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: tone.fg),
                        ),
                      ),
                      Expanded(
                        child: SoftSwitcher(
                          child: KeyedSubtree(key: ValueKey(_i), child: _slide(r)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _number(String text, double size) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(text, style: AppText.h(size, color: _tone.accent, height: 1)),
  );
}
