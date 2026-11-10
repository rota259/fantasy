import 'dart:async';

import '../../../core/notifications/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/confetti.dart';
import '../../../core/widgets/fx/gold_shine.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/formation_pitch.dart';
import '../data/models/week_player.dart';
import '../data/team_of_week.dart';
import '../widgets/totw_pitch.dart';
import '../widgets/totw_story_card.dart';

part 'totw_reveal_screen_sections.dart';

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
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

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
}
