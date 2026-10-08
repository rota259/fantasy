import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../../core/zone/zone_scope.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../events/data/events_repository.dart';
import '../../manager/data/lineup_repository.dart';
import '../../manager/view/manager_challenge_screen.dart';
import '../../manager/view/manager_matches_screen.dart';
import '../../manager/view/manager_players_screen.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/widgets/match_format.dart';
import '../../overlays/view/pitch_overlay.dart';
import '../../players/data/players_repository.dart';
import '../../teams/data/teams_repository.dart';
import '../../teams/view/my_teams_screen.dart';
import '../../week/data/week_window.dart';
import '../../zones/data/zone.dart';
import '../../zones/data/zones_repository.dart';
import '../../../core/widgets/motion.dart';
import '../../tournaments/view/tournaments_screen.dart';

/// رئيسية مدير المنطقة: ماتشاته وفرقه + مواعيد الجولة. (حساب شغل — مفيش فانتازي)
class OrganizerHomeScreen extends StatelessWidget {
  const OrganizerHomeScreen({super.key});

  static const _steps = [
    'اعمل فرقك من "فرقي" — اسم الفريق مميّز ومبيتغيّرش.',
    'اعمل الماتش بين فريقين من فرقك قبل ديدلاين الجولة (السبت ٣ العصر).',
    'لو الديدلاين عدّى اعمله عادي وهيتبعت طلب للإدارة تضيفه.',
    'ضيف اللاعيبة ونزّل التشكيلة، وابعت إشعار "التشكيلة نزلت".',
    'اختار ماتش من ماتشاتك تحدّي للجولة — يوزرز منطقتك يتوقّعوا فرق الأهداف.',
    'وقت الماتش سجّل الأهداف والأسيستات، وفي الآخر اكتب النتيجة واقفله.',
    'لاعيبة الفريقين الموثّقين بيأكدوا الورقة، ولو محدش اعترض خلال ١٢ ساعة النقط بتتعتمد.',
  ];

  void _push(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    final open = WeekWindow.open();
    return Column(
      children: [
        const StatusArea(),
        FutureBuilder<Zone?>(
          future: context.read<ZonesRepository>().byId(ZoneScope.current),
          builder: (context, snap) => Masthead(title: 'منطقتي', subtitle: 'مدير منطقة · ${snap.data?.label ?? ''}'),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ماتشات الجولة الجاية لازم تنزل قبل ${arabicWeekday(open.deadline)} ${arabicTime(open.deadline)}',
                  style: AppText.h(13, color: AppColors.accent400),
                ),
              ),
              if (user != null) ...[
                _tile(context, Icons.sports_outlined, 'ماتشاتي', 'اعمل ماتش · التشكيلة · الأحداث · النتيجة', () {
                  _push(
                    context,
                    ManagerMatchesScreen(
                      matchesRepo: context.read<MatchesRepository>(),
                      playersRepo: context.read<PlayersRepository>(),
                      eventsRepo: context.read<EventsRepository>(),
                      lineupRepo: context.read<LineupRepository>(),
                      organizerId: user.id,
                    ),
                  );
                }),
                _tile(
                  context,
                  Icons.emoji_events_outlined,
                  'البطولات',
                  'اعمل بطولة لمنطقتك — القرعة والجدول والشجرة لوحدهم',
                  () => _push(context, const TournamentsScreen()),
                ),
                _tile(
                  context,
                  Icons.sports_score_outlined,
                  'تحدّي الجولة',
                  'اختار ماتش من ماتشاتك ويوزرز منطقتك يتوقّعوا',
                  () => _push(context, ManagerChallengeScreen(organizerId: user.id)),
                ),
                _tile(
                  context,
                  Icons.location_on_outlined,
                  'احجز ملعب',
                  'الملاعب وحجوزاتك',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => Scaffold(body: PitchOverlay(onClose: () => Navigator.pop(c))),
                    ),
                  ),
                ),
                _tile(context, Icons.groups_outlined, 'لاعيبتي', 'لاعيبة فرقك — احذف واحد أو كذا أو الكل', () async {
                  final teams = await context.read<TeamsRepository>().mine(user.id);
                  if (!context.mounted) return;
                  _push(
                    context,
                    ManagerPlayersScreen(
                      playersRepo: context.read<PlayersRepository>(),
                      teams: [for (final t in teams) t.name],
                    ),
                  );
                }),
                _tile(
                  context,
                  Icons.shield_outlined,
                  'فرقي',
                  'فرقك في المنطقة',
                  () => _push(context, MyTeamsScreen(userId: user.id)),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('إزاي تشتغل', style: AppText.kicker(color: AppColors.accent)),
              ),
              for (final (i, t) in _steps.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text('${i + 1}. $t', style: AppText.body(13)),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'حساب المدير حساب شغل: مش بيعمل تشكيلة ولا بيصوّت ولا بيظهر في الترتيب. '
                  'لو عايز تلعب فانتازي اعمل حساب تاني برقم تاني.',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h(16)),
                  Text(sub, style: AppText.body(11, color: AppColors.neutral700)),
                ],
              ),
            ),
            Text('›', style: AppText.body(18, color: AppColors.neutral600)),
          ],
        ),
      ),
    );
  }
}
