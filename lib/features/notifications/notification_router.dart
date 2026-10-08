import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/auth_cubit.dart';
import '../badges/view/badges_screen.dart';
import '../integrity/view/admin_organizers_screen.dart';
import '../integrity/view/admin_review_screen.dart';
import '../integrity/view/match_review_screen.dart';
import '../manager/view/admin_late_matches_screen.dart';
import '../manager/view/manager_claims_screen.dart';
import '../matches/data/matches_repository.dart';
import '../matches/view/match_center_screen.dart';
import '../players/data/players_repository.dart';
import '../shell/cubit/app_nav_cubit.dart';
import '../week/view/team_of_week_screen.dart';
import '../tournaments/view/tournament_screen.dart';

/// الإشعار بيفتح صفحته: [link] جاي من السيرفر (fn_notification_link) — زي match:ID أو challenge أو totw.
/// نفس الدالة للضغط على الإشعار جوه الأبلكيشن أو على الـ push.
abstract final class NotificationRouter {
  NotificationRouter._();

  static Future<void> open(BuildContext context, {String? link, String? matchId}) async {
    final l = (link == null || link.isEmpty) ? (matchId == null || matchId.isEmpty ? null : 'match:$matchId') : link;
    if (l == null) return;
    final i = l.indexOf(':');
    final kind = i < 0 ? l : l.substring(0, i);
    final arg = i < 0 ? '' : l.substring(i + 1);
    final navigator = Navigator.of(context);
    final nav = context.read<AppNavCubit>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    void push(Widget w) => navigator.push(MaterialPageRoute(builder: (_) => w));
    // التابات والـ overlays تحت كل الصفحات المفتوحة → نرجع للأول
    void home() => navigator.popUntil((r) => r.isFirst);

    try {
      switch (kind) {
        case 'match' || 'review':
          final m = (await context.read<MatchesRepository>().fetchByIds([arg])).firstOrNull;
          if (m == null) throw StateError('match');
          push(kind == 'match' ? MatchCenterScreen(match: m) : MatchReviewScreen(match: m));
        case 'player':
          final p = (await context.read<PlayersRepository>().fetchByIds([arg])).firstOrNull;
          if (p == null) throw StateError('player');
          home();
          nav.openPlayer(p);
        case 'challenge':
          home();
          nav.openOverlay(AppOverlayView.challenge);
        case 'awards':
          home();
          nav.openOverlay(AppOverlayView.awards);
        case 'pitch':
          home();
          nav.openOverlay(AppOverlayView.pitch);
        case 'team' || 'leagues' || 'account' || 'home':
          home();
          nav.setTab(switch (kind) {
            'team' => AppTab.team,
            'leagues' => AppTab.leagues,
            'account' => AppTab.account,
            _ => AppTab.home,
          });
        case 'tournament':
          push(TournamentScreen(id: arg));
        case 'totw':
          push(const TeamOfWeekScreen());
        case 'badges':
          final u = context.read<AuthCubit>().state.user;
          if (u != null) push(BadgesScreen(userId: u.id, userName: u.name));
        case 'admin':
          push(switch (arg) {
            'organizers' => const AdminOrganizersScreen(),
            'late' => const AdminLateMatchesScreen(),
            'claims' => const ManagerClaimsScreen(),
            _ => const AdminReviewScreen(),
          });
      }
    } catch (_) {
      messenger?.showSnackBar(const SnackBar(content: Text('الصفحة دي مبقتش موجودة')));
    }
  }
}
