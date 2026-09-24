part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, ready }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
  });

  final NotificationsStatus status;
  final List<AppNotification> items;

  bool get isLoading => status == NotificationsStatus.loading;

  @override
  List<Object?> get props => [status, items];
}
