import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'leagues_repository.dart';
import 'models/league.dart';
import 'models/league_standing.dart';

/// تنفيذ LeaguesRepository فوق leagues + league_members + profiles.
class SupabaseLeaguesRepository implements LeaguesRepository {
  @override
  Future<int> globalRank(String userId) async {
    // نفس ترتيب الدوري العام (النقط ثم كسر التعادل بالامتلاك)
    final r = await SupabaseService.client.rpc('my_global_rank');
    return (r as num?)?.toInt() ?? 0;
  }

  @override
  Future<List<MyLeague>> myLeagues(String userId) async {
    // طلب واحد: العام + دورياتي بعدد الأعضاء وترتيبي (محسوبين في السيرفر)
    final rows = await SupabaseService.client.rpc('my_leagues') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        MyLeague(
          league: League.fromMap(r).copyWith(memberCount: (r['member_count'] as num).toInt()),
          userRank: (r['my_rank'] as num).toInt(),
        ),
    ];
  }

  @override
  Future<List<LeagueStanding>> standings(String leagueId, {int offset = 0}) async {
    final rows =
        await SupabaseService.client.rpc(
              'league_standings',
              params: {'p_league': leagueId, 'p_offset': offset, 'p_limit': LeagueStanding.pageSize},
            )
            as List;
    return rows.map((r) => LeagueStanding.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createGlobalLeague(String name) async {
    await SupabaseService.client.rpc('create_global_league', params: {'p_name': name});
  }

  @override
  Future<void> joinByCode(String inviteCode) async {
    await SupabaseService.client.rpc('join_league', params: {'p_code': inviteCode.trim()});
  }

  @override
  Future<List<League>> fetchAll() async {
    final rows = await SupabaseService.client.rpc('admin_leagues') as List;
    return rows.map((r) => League.fromMap(r as Map<String, dynamic>)).toList();
  }

  /// كود دعوة من ٦ حروف/أرقام (من غير الحروف اللي بتتلخبط زي O و0).
  static String _code() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Future<League> createLeague(String name, String type, String ownerId) async {
    // لو الكود اتكرّر (نادر جدًا) نجرّب تاني.
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final row = await SupabaseService.table(
          'leagues',
        ).insert({'name': name, 'type': type, 'invite_code': _code(), 'owner_id': ownerId}).select().single();
        final league = League.fromMap(row);
        await SupabaseService.table('league_members').insert({'league_id': league.id, 'user_id': ownerId});
        return league.copyWith(memberCount: 1);
      } on PostgrestException catch (e) {
        if (e.code != '23505' || attempt == 2) rethrow; // 23505 = unique violation
      }
    }
    throw StateError('unreachable');
  }

  @override
  Future<void> deleteLeague(String id) async {
    await SupabaseService.table('leagues').delete().eq('id', id);
  }

  @override
  Future<void> leave(String leagueId, String userId) async {
    await SupabaseService.table('league_members').delete().eq('league_id', leagueId).eq('user_id', userId);
  }
}
