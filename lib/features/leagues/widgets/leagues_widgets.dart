import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../badges/data/models/user_badge.dart';
import '../data/models/league.dart';
import '../data/models/league_standing.dart';
import '../../../core/widgets/motion.dart';

/// هيرو الترتيب العام (أسود) — الترتيب محسوب من نقاط كل المستخدمين.
class LeaguesHero extends StatelessWidget {
  const LeaguesHero({super.key, required this.rank});
  final String rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ترتيبك العام', style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Text(rank, style: AppText.h(44, color: AppColors.white, height: 0.9)),
        ],
      ),
    );
  }
}

/// شريط كود الدعوة للدوري المختار + شيّر + خروج/حذف.
class LeagueCodeBar extends StatelessWidget {
  const LeagueCodeBar({
    super.key,
    required this.league,
    required this.onCopy,
    required this.onLeave,
    required this.isOwner,
  });

  final League league;
  final VoidCallback onCopy;
  final VoidCallback onLeave;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Expanded(child: Text('${league.name} · الترتيب', style: AppText.h(14))),
          if (league.isGlobal)
            Text('كل اليوزرز', style: AppText.h(11, color: AppColors.accent))
          else ...[
            Pressable(
              onTap: onCopy,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(league.inviteCode, style: AppText.h(12, color: AppColors.white, spacingEm: 0.1)),
                    const SizedBox(width: 6),
                    Icon(Icons.share_outlined, size: 14, color: AppColors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              onTap: onLeave,
              child: Icon(isOwner ? Icons.delete_outline : Icons.logout, size: 20, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

/// صف في جدول الترتيب: المركز + الصورة + الاسم + أحسن ٣ شارات + النقط.
class StandingRow extends StatelessWidget {
  const StandingRow({super.key, required this.standing, this.me = false, this.badges = const []});

  final LeagueStanding standing;
  final bool me;
  final List<UserBadge> badges;

  @override
  Widget build(BuildContext context) {
    final s = standing;
    final top = badges.where((b) => b.def != null).take(3).map((b) => b.def!.emoji).join();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: me ? AppColors.accent100 : null,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('${s.rank}', style: AppText.h(14, color: me ? AppColors.accent : AppColors.neutral500)),
          ),
          PentagonAvatar(initials: s.initials, photoUrl: s.photoUrl, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: s.name.isEmpty ? 'يوزر' : s.name, style: AppText.h(13)),
                  if (top.isNotEmpty) TextSpan(text: '  $top', style: const TextStyle(fontSize: 12)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${s.points}', style: AppText.h(14)),
        ],
      ),
    );
  }
}
