import 'package:flutter/material.dart';

import '../../week/widgets/totw_pitch.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../week/data/models/week_player.dart';

part 'star_live_switch.dart';

/// نجم الجولة: الأعلى نقط في منطقتي في الجولة اللي خلصت (نهائي — مبيتغيّرش)،
/// وزرار صغير «الجولة الحالية لحد دلوقتي» بيقلب الكارت على الأعلى في الجولة الشغّالة (من الماتشات المعتمدة).
class StarOfWeekCard extends StatefulWidget {
  const StarOfWeekCard({
    super.key,
    required this.star,
    required this.isFinal,
    required this.fromPrevious,
    required this.label,
    this.liveStar,
    this.liveLabel = '',
    this.onTap,
  });

  final WeekPlayer? star;
  final bool isFinal;
  final bool fromPrevious;
  final String label;
  final WeekPlayer? liveStar;
  final String liveLabel;
  final void Function(WeekPlayer p, bool live)? onTap; // الضغط = عمل إيه في الجولة

  @override
  State<StarOfWeekCard> createState() => _StarOfWeekCardState();
}

class _StarOfWeekCardState extends State<StarOfWeekCard> {
  bool _live = false;

  @override
  Widget build(BuildContext context) {
    final p = _live ? widget.liveStar : widget.star;
    final label = _live ? widget.liveLabel : widget.label;
    final isFinal = !_live && widget.isFinal;
    final onTap = p == null || widget.onTap == null ? null : () => widget.onTap!(p, _live);
    final badge = _live ? '● لحد دلوقتي' : (isFinal ? 'النهائي ✓' : 'الجولة');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _LiveSwitch(live: _live, onChanged: (v) => setState(() => _live = v)),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(key: ValueKey(_live), child: _content(p, label, isFinal, badge, onTap)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(WeekPlayer? p, String label, bool isFinal, String badge, VoidCallback? onTap) {
    return p == null
        ? Row(
            children: [
              IconTile(
                size: 64,
                fill: AppColors.night,
                stroke: AppColors.neutral600,
                child: Icon(Icons.star_outline, color: AppColors.neutral400),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _live
                      ? 'لسه مفيش ماتش اتعتمد في الجولة دي\nأول ما نتيجة ماتش تتعتمد هتلاقي الأعلى هنا'
                      : 'نجم الجولة\nبيظهر أول ما الجولة تخلص',
                  style: AppText.h(13, color: AppColors.white),
                ),
              ),
            ],
          )
        : Row(
            children: [
              GoldAvatar(player: p, size: 92, card: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('نجم الجولة', style: AppText.kicker(color: AppColors.accent400)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: _live ? AppColors.danger : AppColors.accent,
                            borderRadius: AppRadius.sm,
                          ),
                          child: Text(badge, style: AppText.h(9, color: AppColors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h(22, color: AppColors.white),
                    ),
                    Text(
                      '${p.team} · ${p.positionAr}',
                      style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(9, color: AppColors.neutral400),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${p.points}', style: AppText.h(40, color: AppColors.accent400, height: 1)),
                  Text('نقطة', style: AppText.body(10, color: AppColors.white)),
                  if (onTap != null) Text('التفاصيل ›', style: AppText.h(10, color: AppColors.accent400)),
                ],
              ),
            ],
          );
  }
}
