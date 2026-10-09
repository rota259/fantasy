import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_links.dart';
import '../../../core/share/share_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/theme_mode_cubit.dart';
import '../../../core/utils/launchers.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../view/delete_account_screen.dart';
import '../../auth/data/models/app_user.dart';
import '../../claims/view/player_fan_screen.dart';
import '../../fairplay/view/fair_play_screen.dart';
import '../../integrity/view/organizer_request_screen.dart';
import '../../manager/view/manager_hub_screen.dart';
import '../../pitch/view/my_bookings_screen.dart';
import '../../pitch/view/my_venues_screen.dart';
import '../../players/data/models/player.dart';
import '../../seasons/view/season_stars_screen.dart';
import '../../zones/widgets/my_zone_row.dart';
import '../../week/view/team_of_week_screen.dart';
import '../../../core/widgets/motion.dart';

/// قايمة الحساب: تشكيلة الجولة · أنا كلاعب · ملاعبي · حجوزاتي · ادعُ صحابك · التنظيم · لوحة الأدمن · خروج.
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
        _row(Icons.emoji_events_outlined, 'أبطال الموسم (كل المناطق)', () => _push(context, const SeasonStarsScreen())),
        if (lp != null)
          _row(
            Icons.verified_outlined,
            'أنا كلاعب — ${lp.name}',
            () => _push(context, PlayerFanScreen(player: lp)),
            color: AppColors.info,
          ),
        if (u != null) ...[
          MyZoneRow(zoneId: u.zoneId, editable: !u.isOrganizer), // المدير بتنقله الإدارة
          _row(Icons.stadium_outlined, 'ملاعبي (ضيف ملعبك)', () => _push(context, MyVenuesScreen(userId: u.id))),
          _row(Icons.event_available_outlined, 'حجوزاتي', () => _push(context, MyBookingsScreen(userId: u.id))),
          if (u.refCode != null && !u.isOrganizer) _invite(context, u.refCode!),
          if (u.role == 'user')
            _row(
              Icons.sports_outlined,
              'عايز تبقى مدير منطقة؟',
              () => _push(context, OrganizerRequestScreen(userId: u.id)),
            ),
        ],
        if (u?.isManager == true)
          _row(Icons.admin_panel_settings_outlined, 'لوحة الأدمن', () => _push(context, const ManagerHubScreen())),
        BlocBuilder<ThemeModeCubit, ThemeMode>(
          builder: (context, mode) => _row(
            Icons.dark_mode_outlined,
            'المظهر: ${ThemeModeCubit.label(mode)}',
            context.read<ThemeModeCubit>().cycle,
          ),
        ),
        _row(Icons.block_outlined, 'لا للمراهنات · بلّغ', () => _push(context, const FairPlayScreen())),
        _row(Icons.privacy_tip_outlined, 'سياسة الخصوصية', () => Launchers.url(AppLinks.privacy)),
        if (u != null)
          _row(
            Icons.delete_forever_outlined,
            'امسح حسابي',
            () => _push(context, const DeleteAccountScreen()),
            color: AppColors.danger,
          ),
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

  Widget _row(IconData icon, String label, VoidCallback? onTap, {Color? color, bool arrow = true}) {
    final c = color ?? AppColors.ink;
    return Pressable(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppText.h(13, color: c)),
            ),
            if (arrow) Text('›', style: AppText.body(16, color: AppColors.neutral700)),
          ],
        ),
      ),
    );
  }
}
