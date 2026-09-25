import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/data/models/app_user.dart';
import '../../claims/view/player_fan_screen.dart';
import '../../manager/view/manager_hub_screen.dart';
import '../../pitch/view/my_bookings_screen.dart';
import '../../pitch/view/my_venues_screen.dart';
import '../../players/data/models/player.dart';
import '../../week/view/team_of_week_screen.dart';

/// قايمة الحساب: تشكيلة الجولة · أنا كلاعب · ملاعبي · حجوزاتي · ادعُ صحابك · لوحة المدير · خروج.
class AccountMenu extends StatelessWidget {
  const AccountMenu({super.key, required this.user, this.linkedPlayer});

  final AppUser? user;
  final Player? linkedPlayer;

  void _push(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final u = user;
    final lp = linkedPlayer;
    return Column(
      children: [
        _row(Icons.star_border, 'تشكيلة الجولة', () => _push(context, const TeamOfWeekScreen())),
        if (lp != null)
          _row(
            Icons.verified_outlined,
            'أنا كلاعب — ${lp.name}',
            () => _push(context, PlayerFanScreen(player: lp)),
            color: AppColors.info,
          ),
        if (u != null) ...[
          _row(Icons.stadium_outlined, 'ملاعبي (ضيف ملعبك)', () => _push(context, MyVenuesScreen(userId: u.id))),
          _row(Icons.event_available_outlined, 'حجوزاتي', () => _push(context, MyBookingsScreen(userId: u.id))),
          if (u.refCode != null) _invite(context, u.refCode!),
        ],
        if (u?.isManager == true)
          _row(Icons.admin_panel_settings_outlined, 'لوحة المدير', () => _push(context, const ManagerHubScreen())),
        _row(Icons.logout, 'تسجيل الخروج', context.read<AuthCubit>().signOut, color: AppColors.accent, arrow: false),
      ],
    );
  }

  /// كود الدعوة: اللي يسجّل بيه يتحسب في شارة "المؤثر".
  Widget _invite(BuildContext context, String code) =>
      _row(Icons.card_giftcard_outlined, 'ادعُ صحابك · كودك $code', () {
        Clipboard.setData(ClipboardData(text: code));
        ShareCard.text('العب معايا الخماسي — فانتازي ماتشات الخماسي ⚽\nاكتب كود الدعوة بتاعي وانت بتسجّل: $code');
      });

  Widget _row(IconData icon, String label, VoidCallback? onTap, {Color color = AppColors.ink, bool arrow = true}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppText.h(13, color: color)),
            ),
            if (arrow) Text('›', style: AppText.body(16, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }
}
