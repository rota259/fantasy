import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/models/app_user.dart';
import 'profile_repository.dart';

/// تنفيذ ProfileRepository فوق جدول profiles + bucket الصور avatars.
class SupabaseProfileRepository implements ProfileRepository {
  static const _table = 'profiles';
  static const _bucket = 'avatars';

  @override
  Future<AppUser?> fetchMine() async {
    final rows = await SupabaseService.client.rpc('my_profile') as List;
    return rows.isEmpty ? null : AppUser.fromMap(rows.first as Map<String, dynamic>);
  }

  @override
  Future<int> points(String userId) async {
    final row = await SupabaseService.table(_table).select('total_points').eq('id', userId).maybeSingle();
    return (row?['total_points'] as int?) ?? 0;
  }

  @override
  Future<int> bestMatch(String userId) async {
    final rows = await SupabaseService.table(
      'user_match_points',
    ).select('points').eq('user_id', userId).order('points', ascending: false).limit(1);
    return rows.isEmpty ? 0 : (rows.first['points'] as int? ?? 0);
  }

  @override
  Future<void> saveFcmToken(String userId, String token) async {
    await SupabaseService.table(_table).update({'fcm_token': token}).eq('id', userId);
  }

  @override
  Future<String> uploadAvatar(String userId, Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final type = ext == 'png' ? 'image/png' : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
    // فولدر اليوزر بس (السياسة في السيرفر بتمنع غير كده) + اسم جديد كل مرة عشان الكاش
    final path = '$userId/a_${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'jpg' : ext}';
    final storage = SupabaseService.client.storage.from(_bucket);
    await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: type, upsert: true));
    final url = storage.getPublicUrl(path);
    await SupabaseService.table(_table).update({'photo_url': url}).eq('id', userId);
    return url;
  }
}
