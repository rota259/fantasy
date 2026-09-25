import 'package:equatable/equatable.dart';

/// إشعار داخل التطبيق (جدول notifications).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.kind = 'event',
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String kind; // lineup | match | event | status

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'].toString(),
    title: (map['title'] ?? '') as String,
    body: (map['body'] ?? '') as String,
    kind: (map['kind'] ?? 'event') as String,
    createdAt: DateTime.tryParse('${map['created_at']}')?.toLocal() ?? DateTime.now(),
  );

  @override
  List<Object?> get props => [id, title, body, kind, createdAt];
}
