import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_repository.dart';

part 'notifications_state.dart';

/// ViewModel لصندوق الإشعارات.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repo) : super(const NotificationsState());

  final NotificationsRepository _repo;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const NotificationsState(status: NotificationsStatus.ready));
      return;
    }
    emit(const NotificationsState(status: NotificationsStatus.loading));
    try {
      final items = await _repo.fetchRecent();
      emit(NotificationsState(status: NotificationsStatus.ready, items: items));
    } catch (_) {
      emit(const NotificationsState(status: NotificationsStatus.ready));
    }
  }
}
