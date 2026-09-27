import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/zone/zone_scope.dart';
import 'matches_repository.dart';
import 'models/game_match.dart';
import 'models/late_match_request.dart';

/// تنفيذ MatchesRepository فوق جدول matches في Supabase.
class SupabaseMatchesRepository implements MatchesRepository {
  static const _table = 'matches';

  @override
  Future<List<GameMatch>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> fetchOrganizedBy(String userId) async {
    final rows = await SupabaseService.table(
      _table,
    ).select().eq('organizer_id', userId).order('date_time', ascending: false).limit(50);
    return rows.map(GameMatch.fromMap).toList();
  }

  /// ماتشات منطقتي + العامة.
  static PostgrestFilterBuilder<List<Map<String, dynamic>>> _mine() {
    final zone = ZoneScope.orFilter;
    final q = SupabaseService.table(_table).select();
    return zone == null ? q : q.or(zone);
  }

  @override
  Future<List<GameMatch>> fetchInWindow(DateTime start, DateTime end) async {
    final rows = await _mine()
        .gte('date_time', start.toUtc().toIso8601String())
        .lte('date_time', end.toUtc().toIso8601String())
        .order('date_time');
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> fetchUpcoming() async {
    final rows = await _mine().eq('status', 'upcoming').order('date_time').limit(50);
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<void> addMatch({required List<String> teams, required DateTime dateTime, required int week}) async {
    await SupabaseService.table(
      _table,
    ).insert({'teams': teams, 'date_time': GameMatch.dbTime(dateTime), 'week': week, 'status': 'upcoming'});
  }

  @override
  Future<List<GameMatch>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await SupabaseService.table(_table).select().inFilter('id', ids);
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<List<GameMatch>> fetchFinished() async {
    final rows = await _mine().eq('status', 'finished').order('date_time', ascending: false).limit(20);
    return rows.map(GameMatch.fromMap).toList();
  }

  @override
  Future<void> finishMatch(String id, int scoreA, int scoreB) async {
    final rows = await SupabaseService.table(
      _table,
    ).update({'status': 'finished', 'score_a': scoreA, 'score_b': scoreB}).eq('id', id).select('id');
    _ensureWritten(rows);
  }

  /// الـ RLS بترجّع صفر صفوف من غير خطأ — نحوّلها لرسالة مفهومة.
  static void _ensureWritten(List rows) {
    if (rows.isEmpty) {
      throw const PostgrestException(message: 'مينفعش تعدّل الماتش ده دلوقتي (اتعتمد أو عليه اعتراض)');
    }
  }

  @override
  Future<void> updateMatch(
    String id, {
    required List<String> teams,
    required DateTime dateTime,
    required int week,
  }) async {
    final rows = await SupabaseService.table(
      _table,
    ).update({'teams': teams, 'date_time': GameMatch.dbTime(dateTime), 'week': week}).eq('id', id).select('id');
    _ensureWritten(rows);
  }

  @override
  Future<int> deleteMatch(String id) async {
    final rows = await SupabaseService.table(_table).delete().eq('id', id).select('id');
    return rows.length;
  }

  @override
  Future<void> requestLateMatch({required List<String> teams, required DateTime dateTime, String? note}) async {
    await SupabaseService.client.rpc(
      'request_late_match',
      params: {'p_teams': teams, 'p_when': dateTime.toUtc().toIso8601String(), 'p_note': note},
    );
  }

  @override
  Future<List<LateMatchRequest>> pendingLateMatches() async {
    final rows = await SupabaseService.client.rpc('admin_late_match_requests') as List;
    return rows.cast<Map<String, dynamic>>().map(LateMatchRequest.fromMap).toList();
  }

  @override
  Future<void> reviewLateMatch(String requestId, bool approve) async {
    await SupabaseService.client.rpc('review_late_match', params: {'p_req': requestId, 'p_approve': approve});
  }
}
