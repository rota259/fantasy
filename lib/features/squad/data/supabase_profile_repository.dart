import '../../../core/supabase/supabase_service.dart';
import '../../auth/data/models/app_user.dart';
import 'profile_repository.dart';

/// تنفيذ ProfileRepository فوق جدول profiles.
class SupabaseProfileRepository implements ProfileRepository {
  static const _table = 'profiles';

  @override
  Future<void> updateTeam(String userId, List<String> playerIds, String? captainId) async {
    await SupabaseService.table(_table)
        .update({'team': playerIds, 'captain_id': captainId})
        .eq('id', userId);
  }

  @override
  Future<AppUser?> fetchProfile(String userId) async {
    final row =
        await SupabaseService.table(_table).select().eq('id', userId).maybeSingle();
    return row == null ? null : AppUser.fromMap(row);
  }

  @override
  Future<void> saveFcmToken(String userId, String token) async {
    await SupabaseService.table(_table).update({'fcm_token': token}).eq('id', userId);
  }
}
