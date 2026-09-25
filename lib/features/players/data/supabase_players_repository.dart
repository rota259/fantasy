import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'models/player.dart';
import 'players_repository.dart';

/// تنفيذ PlayersRepository فوق جدول players في Supabase.
class SupabasePlayersRepository implements PlayersRepository {
  static const _table = 'players';

  @override
  Future<List<Player>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('name');
    return rows.map(Player.fromMap).toList();
  }

  @override
  Future<List<Player>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await SupabaseService.table(_table).select().inFilter('id', ids);
    return rows.map(Player.fromMap).toList();
  }

  @override
  Future<List<Player>> fetchByTeams(List<String> teams) async {
    if (teams.isEmpty) return const [];
    final rows = await SupabaseService.table(_table).select().inFilter('team', teams);
    return rows.map(Player.fromMap).toList();
  }

  @override
  Future<String> addPlayer({required String name, required String team, required String position}) async {
    final rows = await SupabaseService.table(
      _table,
    ).insert({'name': name, 'team': team, 'position': position}).select('id');
    return rows.first['id'].toString();
  }

  @override
  Future<int> deletePlayer(String id) async {
    // .select() بيرجّع الصفوف المحذوفة فعلًا — 0 يعني RLS منع الحذف (مش مدير).
    final rows = await SupabaseService.table(_table).delete().eq('id', id).select('id');
    return rows.length;
  }

  @override
  Future<void> updatePlayer(String id, {required String name, required String team, required String position}) async {
    await SupabaseService.table(_table).update({'name': name, 'team': team, 'position': position}).eq('id', id);
  }

  @override
  Future<void> setAvailability(String id, String availability, String? news) async {
    await SupabaseService.table(_table).update({'availability': availability, 'news': news}).eq('id', id);
  }

  @override
  Future<String> uploadPhoto(String id, Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final type = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    final path = '$id/p_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
    final storage = SupabaseService.client.storage.from('player-photos');
    await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type, upsert: true));
    final url = storage.getPublicUrl(path);
    await SupabaseService.table(_table).update({'image_url': url}).eq('id', id);
    return url;
  }
}
