import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/confetti.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../data/models/week_player.dart';
import '../data/team_of_week.dart';
import '../widgets/totw_story_card.dart';

/// كشف تشكيلة الجولة زي فتح الباكات: الشاشة تضلم والكروت تنزل واحد واحد (الحارس الأول وبعدين من الأقل
/// للأعلى)، وفي الآخر نجم الجولة بإضاءة دهبي + confetti — وبعدها كارت story جاهز للشير.
class TotwRevealScreen extends StatefulWidget {
  const TotwRevealScreen({super.key, required this.team, required this.label, this.refCode});
  final List<WeekPlayer> team;
  final String label; // المنطقة · الجولة
  final String? refCode;

  static Future<void> open(BuildContext context, List<WeekPlayer> team, String label, {String? refCode}) =>
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, _, _) => TotwRevealScreen(team: team, label: label, refCode: refCode),
          transitionsBuilder: (_, a, _, c) => FadeTransition(opacity: a, child: c),
        ),
      );

  @override
  State<TotwRevealScreen> createState() => _TotwRevealScreenState();
}

class _TotwRevealScreenState extends State<TotwRevealScreen> {
  late final List<WeekPlayer> _order; // ترتيب الكشف (النجم آخر واحد)
  late final WeekPlayer? _star = TeamOfWeek.starOf(widget.team);
  final _cardKey = GlobalKey();
  int _shown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final rest = [...widget.team.where((p) => p != _star)]
      ..sort((a, b) {
        if (a.position == 'GK') return -1;
        if (b.position == 'GK') return 1;
        return a.points.compareTo(b.points);
      });
    _order = [...rest, ?_star];
    _timer = Timer.periodic(const Duration(milliseconds: 1100), (_) => _next());
    Future.delayed(const Duration(milliseconds: 350), _next);
  }

  void _next() {
    if (!mounted || _shown >= _order.length) return;
    setState(() => _shown++);
    _shown == _order.length ? HapticFeedback.heavyImpact() : HapticFeedback.lightImpact();
    if (_shown == _order.length) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _shown >= _order.length;
    return GestureDetector(
      onTap: done ? null : () => setState(() => _shown = _order.length), // تخطّي
      child: Material(
        color: Colors.black.withValues(alpha: 0.92),
        child: SafeArea(
          child: Stack(
            children: [
              if (done) const Positioned.fill(child: ConfettiBurst(count: 110)),
              Center(child: done ? _final() : _revealing()),
              if (!done)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Text(
                    'دوس في أي حتة للتخطّي',
                    textAlign: TextAlign.center,
                    style: AppText.body(11, color: AppColors.neutral400),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// الكارت اللي بينزل دلوقتي + اللي اتكشفوا فوق.
  Widget _revealing() {
    final i = _shown - 1;
    final isStar = i == _order.length - 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('⭐ تشكيلة الجولة', style: AppText.h(22, color: Colors.white)),
        const SizedBox(height: 26),
        if (i >= 0)
          TweenAnimationBuilder<double>(
            key: ValueKey(i),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: Motion.reduced(context) ? 1 : 650),
            curve: Curves.easeOutBack,
            builder: (_, t, c) => Opacity(
              opacity: t.clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, -220 * (1 - t)),
                child: Transform.scale(scale: 1.4 - 0.4 * t, child: c),
              ),
            ),
            child: _bigCard(_order[i], star: isStar),
          ),
      ],
    );
  }

  Widget _bigCard(WeekPlayer p, {bool star = false}) {
    const gold = Color(0xFFF2C14E);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: star ? [const Color(0xFF7A5A12), gold] : [AppColors.navy, AppColors.night],
        ),
        boxShadow: [BoxShadow(color: (star ? gold : AppColors.info).withValues(alpha: 0.6), blurRadius: 30)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p.positionAr, style: AppText.kicker(color: Colors.white70)),
          const SizedBox(height: 10),
          PentagonAvatar(initials: p.initials, photoUrl: p.imageUrl, size: 96, verified: p.verified),
          const SizedBox(height: 10),
          Text(
            p.name,
            textAlign: TextAlign.center,
            style: AppText.h(18, color: Colors.white),
          ),
          Text(p.team, style: AppText.body(11, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('${p.points}', style: AppText.h(36, color: star ? Colors.black : gold)),
          if (star) Text('⭐ نجم الجولة', style: AppText.h(14, color: Colors.black)),
        ],
      ),
    );
  }

  /// النهاية: كارت story جاهز للشير.
  Widget _final() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: RepaintBoundary(
              key: _cardKey,
              child: TotwStoryCard(team: widget.team, label: widget.label, refCode: widget.refCode),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => ShareCard.share(
                  _cardKey,
                  'تشكيلة الجولة في ${widget.label} ⭐ — نجمها ${_star?.name ?? ''}\nالعب الخماسي'
                  '${widget.refCode == null ? '' : ' بكود ${widget.refCode}'}',
                ),
                icon: const Icon(Icons.ios_share),
                label: const Text('شيّر'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('تمام'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
