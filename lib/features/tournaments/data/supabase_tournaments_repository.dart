import '../../../core/supabase/supabase_service.dart';
import '../../matches/data/models/game_match.dart';
import 'models/tournament.dart';
import 'tournaments_repository.dart';

/// تنفيذ TournamentsRepository فوق جداول البطولات ودوالها.
class SupabaseTournamentsRepository implements TournamentsRepository {
  static Future<List<Map<String, dynamic>>> _rpc(String fn, [Map<String, dynamic>? p]) async =>
      (await SupabaseService.client.rpc(fn, params: p) as List).cast<Map<String, dynamic>>();

  @override
  Future<List<Tournament>> list(int zoneId) async {
    final rows = await SupabaseService.table(
      'tournaments',
    ).select().eq('zone_id', zoneId).order('created_at', ascending: false).limit(50);
    return rows.map(Tournament.fromMap).toList();
  }

  @override
  Future<Tournament?> byId(String id) async {
    final row = await SupabaseService.table('tournaments').select().eq('id', id).maybeSingle();
    return row == null ? null : Tournament.fromMap(row);
  }

  @override
  Future<List<TournamentTeam>> teams(String id) async {
    final rows = await SupabaseService.table(
      'tournament_teams',
    ).select().eq('tournament_id', id).neq('status', 'rejected').order('group_label').order('created_at');
    return rows.map(TournamentTeam.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> matches(String id) async {
    final rows = await SupabaseService.table('matches').select().eq('tournament_id', id).order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<TournamentRow>> standings(String id) async =>
      (await _rpc('tournament_standings', {'p_t': id})).map(TournamentRow.fromMap).toList();

  @override
  Future<List<BracketSlot>> bracket(String id) async {
    final rows = await SupabaseService.table(
      'tournament_bracket',
    ).select().eq('tournament_id', id).order('round').order('slot');
    return rows.map(BracketSlot.fromMap).toList();
  }

  @override
  Future<List<TournamentAward>> awards(String id) async =>
      (await _rpc('tournament_awards', {'p_t': id})).map(TournamentAward.fromMap).toList();

  @override
  Future<(String?, Map<String, int>)> predictions(String id, String userId) async {
    final rows = await SupabaseService.table('tournament_predictions').select('user_id, team').eq('tournament_id', id);
    String? mine;
    final counts = <String, int>{};
    for (final r in rows) {
      final team = r['team'] as String;
      counts[team] = (counts[team] ?? 0) + 1;
      if (r['user_id'].toString() == userId) mine = team;
    }
    return (mine, counts);
  }

  @override
  Future<String> create({
    required String name,
    required String format,
    required int teamCount,
    required int groups,
    required DateTime startsAt,
    String? prize,
    String? sponsor,
    int? zoneId,
  }) async {
    final id = await SupabaseService.client.rpc(
      'create_tournament',
      params: {
        'p_name': name,
        'p_format': format,
        'p_team_count': teamCount,
        'p_groups': groups,
        'p_starts': startsAt.toUtc().toIso8601String(),
        'p_prize': prize,
        'p_sponsor': sponsor,
        'p_zone': zoneId,
      },
    );
    return id.toString();
  }

  Future<void> _call(String fn, Map<String, dynamic> p) => SupabaseService.client.rpc(fn, params: p);

  @override
  Future<void> addTeam(String id, String team) => _call('add_tournament_team', {'p_t': id, 'p_team': team});

  @override
  Future<void> requestTeam(String id, String team, String phone, String? note) =>
      _call('request_tournament_team', {'p_t': id, 'p_team': team, 'p_phone': phone, 'p_note': note});

  @override
  Future<void> reviewTeam(String id, String team, bool approve) =>
      _call('review_tournament_team', {'p_t': id, 'p_team': team, 'p_approve': approve});

  @override
  Future<void> draw(String id) => _call('draw_tournament', {'p_t': id});

  @override
  Future<void> startKnockout(String id) => _call('start_knockout', {'p_t': id});

  @override
  Future<void> setWinner(String matchId, String team) =>
      _call('set_match_winner', {'p_match': matchId, 'p_team': team});

  @override
  Future<void> predict(String id, String team) => _call('predict_champion', {'p_t': id, 'p_team': team});
}
