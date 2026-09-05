import '../../../core/supabase/supabase_service.dart';
import 'leagues_repository.dart';
import 'models/league.dart';
import 'models/league_standing.dart';

/// تنفيذ LeaguesRepository فوق leagues + league_members + profiles.
class SupabaseLeaguesRepository implements LeaguesRepository {
  @override
  Future<int> globalRank(String userId) async {
    final me = await SupabaseService.table('profiles')
        .select('total_points')
        .eq('id', userId)
        .single();
    final myPoints = (me['total_points'] ?? 0) as int;
    final above = await SupabaseService.table('profiles')
        .select('id')
        .gt('total_points', myPoints);
    return above.length + 1;
  }

  @override
  Future<List<MyLeague>> myLeagues(String userId) async {
    final rows = await SupabaseService.table('league_members')
        .select('leagues(id,name,type,invite_code)')
        .eq('user_id', userId);

    final result = <MyLeague>[];
    for (final row in rows) {
      final data = row['leagues'] as Map<String, dynamic>?;
      if (data == null) continue;
      final table = await standings(data['id'].toString());
      final rank = table.indexWhere((s) => s.userId == userId) + 1;
      result.add(MyLeague(
        league: League.fromMap(data).copyWith(memberCount: table.length),
        userRank: rank,
      ));
    }
    return result;
  }

  @override
  Future<List<LeagueStanding>> standings(String leagueId) async {
    final rows = await SupabaseService.table('league_members')
        .select('user_id, profiles(name, total_points)')
        .eq('league_id', leagueId);

    final members = rows.map((r) {
      final p = (r['profiles'] as Map<String, dynamic>?) ?? const {};
      return (
        userId: r['user_id'].toString(),
        name: (p['name'] ?? '') as String,
        points: (p['total_points'] ?? 0) as int,
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    return [
      for (var i = 0; i < members.length; i++)
        LeagueStanding(
          rank: i + 1,
          userId: members[i].userId,
          name: members[i].name,
          points: members[i].points,
        ),
    ];
  }

  @override
  Future<void> joinByCode(String inviteCode, String userId) async {
    final league = await SupabaseService.table('leagues')
        .select('id')
        .eq('invite_code', inviteCode)
        .single();
    await SupabaseService.table('league_members').upsert(
      {'league_id': league['id'], 'user_id': userId},
      onConflict: 'league_id,user_id',
    );
  }
}
