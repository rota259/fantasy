import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/confetti.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../week/data/week_window.dart';
import '../data/points_repository.dart';
import '../data/round_recap.dart';
import '../widgets/round_story_card.dart';

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

  void _go(int d) {
    final n = (_i + d).clamp(0, _slides - 1);
    if (n == _i && d > 0) return _bar.stop(); // آخر سلايد بيفضل
    setState(() => _i = n);
    _bar.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1A12),
      body: SafeArea(
        child: FutureBuilder<RoundRecap>(
          future: _recap,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Text('تعذّر التحميل', style: AppText.body(14, color: Colors.white)),
              );
            }
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final r = snap.data!;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              // RTL: الضغط على الشمال = اللي بعده
              onTapUp: (d) => _go(d.localPosition.dx < MediaQuery.sizeOf(context).width / 2 ? 1 : -1),
              child: Column(
                children: [
                  _progress(),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
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
    );
  }

  Widget _progress() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: Row(
      children: [
        for (var k = 0; k < _slides; k++)
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              alignment: AlignmentDirectional.centerStart,
              child: k < _i
                  ? Container(color: Colors.white)
                  : k == _i
                  ? AnimatedBuilder(
                      animation: _bar,
                      builder: (_, _) => FractionallySizedBox(
                        widthFactor: _bar.value,
                        child: Container(color: Colors.white),
                      ),
                    )
                  : null,
            ),
          ),
      ],
    ),
  );

  Widget _slide(RoundRecap r) => switch (_i) {
    0 => _big(
      'جولتك',
      CountUp(
        value: r.points,
        style: AppText.h(96, color: AppColors.accent400),
      ),
      'نقطة',
      extra: r.chip == null ? null : '🃏 لعبت بكارت',
    ),
    1 => _big(
      'أحسن اختيار ليك',
      Text(r.bestName ?? '—', style: AppText.h(40, color: Colors.white)),
      '${r.bestPoints} نقطة',
      extra: r.bestPoints >= 10 ? 'عين صقر 🦅' : null,
    ),
    2 => _big(
      'الكابتن',
      Text(r.captainName ?? '—', style: AppText.h(40, color: const Color(0xFFF2C14E))),
      '${r.captainPoints} × ٢ = ${r.captainPoints * 2} نقطة',
      extra: r.captainPoints * 2 >= 10 ? 'كابتن صح 🔥' : 'المرة الجاية تختار أحسن 😅',
    ),
    3 => _rank(r),
    _ => _share(r),
  };

  Widget _big(String title, Widget value, String sub, {String? extra}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppText.h(20, color: Colors.white70)),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.elasticOut,
          builder: (_, s, c) => Transform.scale(scale: s, child: c),
          child: value,
        ),
        const SizedBox(height: 8),
        Text(sub, style: AppText.h(18, color: Colors.white)),
        if (extra != null) ...[
          const SizedBox(height: 18),
          FadeSlideIn(
            index: 6,
            child: Text(extra, style: AppText.h(16, color: AppColors.accent400)),
          ),
        ],
      ],
    ),
  );

  Widget _rank(RoundRecap r) {
    final m = r.moved;
    return Stack(
      children: [
        if (m > 0) const Positioned.fill(child: ConfettiBurst(count: 60)),
        _big(
          'ترتيبك في الدوري العام',
          Text('#${r.rankNow}', style: AppText.h(80, color: Colors.white)),
          'من ${r.users} لاعب',
          extra: m > 0 ? '⬆ طلعت $m مركز' : (m < 0 ? '⬇ نزلت ${-m} مركز' : 'ثابت في مكانك'),
        ),
      ],
    );
  }

  Widget _share(RoundRecap r) {
    final user = context.read<AuthCubit>().state.user;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: RepaintBoundary(
              key: _cardKey,
              child: RoundStoryCard(
                recap: r,
                name: user?.name ?? '',
                label: widget.window.label,
                refCode: user?.refCode,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ShareCard.share(
              _cardKey,
              'جبت ${r.points} نقطة الجولة دي في الخماسي ⚽ وترتيبي #${r.rankNow}'
              '${user?.refCode == null ? '' : '\nالعب معايا بكود ${user!.refCode}'}',
            ),
            icon: const Icon(Icons.ios_share),
            label: const Text('شيّر جولتك'),
          ),
        ],
      ),
    );
  }
}
