import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'models/venue.dart';
import 'models/venue_extras.dart';
import 'venues_repository.dart';

/// تنفيذ VenuesRepository فوق جدول venues + Storage bucket venue-photos.
class SupabaseVenuesRepository implements VenuesRepository {
  static const _table = 'venues';
  static const _bucket = 'venue-photos';

  @override
  Future<List<Venue>> fetchAll() async {
    final rows = await SupabaseService.table(_table).select().order('name');
    return rows.map(Venue.fromMap).toList();
  }

  @override
  Future<Venue?> fetchById(String id) async {
    final row = await SupabaseService.table(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : Venue.fromMap(row);
  }

  @override
  Future<List<Venue>> fetchOwned(String userId) async {
    final rows = await SupabaseService.table(_table).select().eq('owner_id', userId).order('name');
    return rows.map(Venue.fromMap).toList();
  }

  @override
  Future<void> save(Venue venue) async {
    if (venue.id.isEmpty) {
      await SupabaseService.table(_table).insert(venue.toWrite());
    } else {
      await SupabaseService.table(_table).update(venue.toWrite()).eq('id', venue.id);
    }
  }

  @override
  Future<void> deleteVenue(String id) async {
    await SupabaseService.table(_table).delete().eq('id', id);
  }

  @override
  Future<Map<String, ({double avg, int count})>> ratings() async {
    final rows = await SupabaseService.client.rpc('venue_ratings') as List;
    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        r['venue_id'].toString(): (avg: (r['avg'] as num).toDouble(), count: (r['count'] as num).toInt()),
    };
  }

  @override
  Future<String> uploadPhoto(String userId, Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final type = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    // فولدر اليوزر (السياسة في السيرفر بتمنع يرفع في فولدر حد تاني)
    final path = '$userId/v_${DateTime.now().microsecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
    final storage = SupabaseService.client.storage.from(_bucket);
    await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
    return storage.getPublicUrl(path);
  }

  @override
  Future<void> verify(String id, bool on) =>
      SupabaseService.client.rpc('verify_venue', params: {'p_venue': id, 'p_on': on});

  @override
  Future<void> requestVerification(String id) =>
      SupabaseService.client.rpc('request_venue_verification', params: {'p_venue': id});

  @override
  Future<List<PendingVenue>> pending() async {
    final rows = await SupabaseService.client.rpc('pending_venues') as List;
    return [for (final r in rows) PendingVenue.fromMap(Map<String, dynamic>.from(r as Map))];
  }

  @override
  Future<void> postUpdate(String id, String kind, String body) =>
      SupabaseService.client.rpc('post_venue_update', params: {'p_venue': id, 'p_kind': kind, 'p_body': body});

  @override
  Future<List<VenueUpdate>> updates(String id) async {
    final rows = await SupabaseService.table(
      'venue_updates',
    ).select().eq('venue_id', id).order('created_at', ascending: false).limit(5);
    return rows.map(VenueUpdate.fromMap).toList();
  }

  @override
  Future<VenueStats> stats(String id) async {
    final r = await SupabaseService.client.rpc('venue_stats', params: {'p_venue': id});
    return VenueStats.fromMap(Map<String, dynamic>.from(r as Map));
  }

  @override
  Future<bool> amHost() async => (await SupabaseService.client.rpc('is_venue_host')) == true;

  @override
  Future<List<VenueMatch>> pendingMatches(String venueId) async {
    final rows = await SupabaseService.client.rpc('venue_pending_matches', params: {'p_venue': venueId}) as List;
    return [for (final r in rows) VenueMatch.fromMap(Map<String, dynamic>.from(r as Map))];
  }

  @override
  Future<void> confirmMatch(String matchId, bool ok, String? note) =>
      SupabaseService.client.rpc('venue_confirm_match', params: {'p_match': matchId, 'p_ok': ok, 'p_note': note});
}
