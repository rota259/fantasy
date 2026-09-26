import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'team.dart';
import 'teams_repository.dart';

/// تنفيذ TeamsRepository فوق جدول teams (الحماية والمنطقة في trigger السيرفر).
class SupabaseTeamsRepository implements TeamsRepository {
  static const _table = 'teams';

  @override
  Future<List<Team>> mine(String userId) async {
    final rows = await SupabaseService.table(_table).select().eq('owner_id', userId).order('name');
    return rows.map(Team.fromMap).toList();
  }

  @override
  Future<List<Team>> all() async {
    final rows = await SupabaseService.table(_table).select('*, owner:profiles!owner_id(name)').order('name');
    return rows.map(Team.fromMap).toList();
  }

  @override
  Future<void> create(String name) async {
    await SupabaseService.table(_table).insert({'name': name.trim()});
  }

  @override
  Future<void> delete(String id) async {
    final rows = await SupabaseService.table(_table).delete().eq('id', id).select('id');
    if (rows.isEmpty) {
      throw const PostgrestException(message: 'مينفعش تحذف فريق عليه لاعيبة أو ماتشات');
    }
  }

  @override
  Future<void> setZone(String id, int zoneId) async {
    await SupabaseService.table(_table).update({'zone_id': zoneId}).eq('id', id);
  }
}
