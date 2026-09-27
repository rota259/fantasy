import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../badges/data/badges_repository.dart';
import '../../badges/data/models/user_badge.dart';
import '../data/leagues_repository.dart';
import '../data/models/league.dart';
import '../data/models/league_standing.dart';
import '../../../core/utils/perf.dart';

part 'leagues_state.dart';

/// ViewModel للدوريات: الترتيب العام + دورياتي + جدول الترتيب (بالصور والشارات)
/// + إنشاء دوري / انضمام / خروج / حذف (لصاحبه).
class LeaguesCubit extends Cubit<LeaguesState> {
  LeaguesCubit(this._repo, this._badges) : super(const LeaguesState());

  final LeaguesRepository _repo;
  final BadgesRepository _badges;
  String? _userId;

  Future<void> load(String? userId, {String? select}) async {
    _userId = userId;
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const LeaguesState(status: LeaguesStatus.loaded));
      return;
    }
    if (state.status == LeaguesStatus.initial) emit(const LeaguesState(status: LeaguesStatus.loading));
    try {
      final (rank, leagues) = await timed('leagues', () => (_repo.globalRank(userId), _repo.myLeagues(userId)).wait);
      final id = leagues.any((l) => l.league.id == select) ? select : leagues.firstOrNull?.league.id;
      emit(LeaguesState(status: LeaguesStatus.loaded, globalRank: rank, myLeagues: leagues, selectedLeagueId: id));
      if (id != null) await selectLeague(id);
    } catch (_) {
      emit(const LeaguesState(status: LeaguesStatus.loaded));
    }
  }

  Future<void> selectLeague(String leagueId) async {
    emit(state.copyWith(selectedLeagueId: leagueId, standings: const [], hasMore: false));
    await _page(leagueId, const []);
  }

  /// الصفحة الجاية من الترتيب (٥٠ كمان).
  Future<void> loadMore() async {
    final id = state.selectedLeagueId;
    if (id != null && state.hasMore) await _page(id, state.standings);
  }

  Future<void> _page(String leagueId, List<LeagueStanding> before) async {
    try {
      final page = await _repo.standings(leagueId, offset: before.length);
      final badges = await _badges.earnedFor(page.map((s) => s.userId).toList());
      if (isClosed || state.selectedLeagueId != leagueId) return;
      emit(
        state.copyWith(
          standings: [...before, ...page],
          badges: {...state.badges, ...badges},
          hasMore: page.length == LeagueStanding.pageSize,
        ),
      );
    } catch (_) {}
  }

  Future<String> join(String inviteCode) async {
    if (_userId == null) return 'سجّل دخولك الأول';
    try {
      await _repo.joinByCode(inviteCode);
      await load(_userId);
      return 'اتنضممت للدوري ✓';
    } catch (e) {
      return dbMessage(e, fallback: 'كود غير صحيح');
    }
  }

  /// بيرجّع كود الدعوة أو يرمي رسالة.
  Future<League> create(String name, String type) async {
    final uid = _userId;
    if (uid == null) throw StateError('سجّل دخولك الأول');
    final l = await _repo.createLeague(name, type, uid);
    await load(uid, select: l.id);
    return l;
  }

  Future<String> leaveOrDelete(League l) async {
    final uid = _userId;
    if (uid == null) return '';
    try {
      l.ownerId == uid ? await _repo.deleteLeague(l.id) : await _repo.leave(l.id, uid);
      await load(uid);
      return l.ownerId == uid ? 'اتمسح الدوري' : 'خرجت من الدوري';
    } catch (e) {
      return dbMessage(e);
    }
  }
}
