import '../../../core/supabase/supabase_service.dart';
import 'models/player.dart';
import 'players_repository.dart';

/// تنفيذ PlayersRepository فوق جدول players في Supabase.
class SupabasePlayersRepository implements PlayersRepository {
  static const _table = 'players';

  @override
  Future<List<Player>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('price');
    return rows.map(Player.fromMap).toList();
  }

  @override
  Future<List<Player>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows =
        await SupabaseService.table(_table).select().inFilter('id', ids);
    return rows.map(Player.fromMap).toList();
  }

  @override
  Future<List<Player>> fetchByTeams(List<String> teams) async {
    if (teams.isEmpty) return const [];
    final rows =
        await SupabaseService.table(_table).select().inFilter('team', teams);
    return rows.map(Player.fromMap).toList();
  }

  @override
  Future<String> addPlayer({
    required String name,
    required String team,
    required String position,
    required double price,
  }) async {
    final rows = await SupabaseService.table(_table).insert({
      'name': name,
      'team': team,
      'position': position,
      'price': price,
    }).select('id');
    return rows.first['id'].toString();
  }

  @override
  Future<void> deletePlayer(String id) async {
    await SupabaseService.table(_table).delete().eq('id', id);
  }
}
