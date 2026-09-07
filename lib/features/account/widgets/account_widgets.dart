import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';

/// ترويسة الحساب (سوداء) — أفاتار + اسم + شارة.
class AccountHeader extends StatelessWidget {
  const AccountHeader({super.key, this.user});
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final u = user;
    final initials = u != null ? u.initials : 'MK';
    final name = (u != null && u.name.isNotEmpty) ? u.name : 'محمد كمال';
    final handle = u != null
        ? '@${u.email.split('@').first}${u.createdAt != null ? ' · عضو من ${u.createdAt!.year}' : ''}'
        : '@mk_khamasy · عضو من 2024';
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Row(
        children: [
          Container(
            width: 60, height: 60, alignment: Alignment.center,
            color: AppColors.accent,
            child: Text(initials, style: AppText.h(22, color: AppColors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppText.h(22, color: AppColors.white)),
                const SizedBox(height: 3),
                Text(handle,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شبكة إحصائيات + أوراق (chips).
class AccountStats extends StatelessWidget {
  const AccountStats({super.key, this.user, this.rank, this.live = false});
  final AppUser? user;
  final int? rank;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final points = user != null ? '${user!.totalPoints}' : '—';
    final rankText = (rank ?? 0) > 0 ? '$rank' : '—';
    const bestGw = '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
          ),
          child: Row(children: [
            _stat(points, 'إجمالي النقاط', border: true),
            _stat(rankText, 'الترتيب العام', border: true),
            _stat(bestGw, 'أفضل جولة', color: AppColors.accent),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text('أوراقك · CHIPS', style: AppText.kicker()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            _chip('كابتن ×3', 'متاح', on: true),
            const SizedBox(width: 8),
            _chip('وايلد كارد', 'متاح', on: true),
            const SizedBox(width: 8),
            _chip('دكّة', 'GW3 ✓', on: false),
          ]),
        ),
      ],
    );
  }

  Widget _stat(String v, String k, {bool border = false, Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: border ? const Border(left: BorderSide(color: AppColors.divider)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v, style: AppText.h(22, color: color ?? AppColors.ink)),
            Text(k, style: AppText.body(9, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, String s, {required bool on}) {
    return Expanded(
      child: Opacity(
        opacity: on ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            border: Border.all(color: on ? AppColors.black : AppColors.divider, width: 2),
          ),
          child: Column(children: [
            Text(t, style: AppText.h(11)),
            Text(s, style: AppText.body(8, color: AppColors.neutral700)),
          ]),
        ),
      ),
    );
  }
}
