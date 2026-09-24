import '../../../core/supabase/supabase_service.dart';
import 'models/app_notification.dart';
import 'notifications_repository.dart';

/// تنفيذ NotificationsRepository فوق جدول notifications.
class SupabaseNotificationsRepository implements NotificationsRepository {
  static const _table = 'notifications';

  @override
  Future<List<AppNotification>> fetchRecent() async {
    final rows = await SupabaseService.table(_table)
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return rows.map(AppNotification.fromMap).toList();
  }

  @override
  Future<void> add({
    required String title,
    required String body,
    String kind = 'event',
    String? matchId,
  }) async {
    await SupabaseService.table(_table)
        .insert({'title': title, 'body': body, 'kind': kind, 'match_id': matchId});
  }
}
