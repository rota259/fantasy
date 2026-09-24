import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import 'models/venue.dart';
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
  Future<String> uploadPhoto(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final type = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    final path = 'v_${DateTime.now().microsecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
    final storage = SupabaseService.client.storage.from(_bucket);
    await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type));
    return storage.getPublicUrl(path);
  }
}
