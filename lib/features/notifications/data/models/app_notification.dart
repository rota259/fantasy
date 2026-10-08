import 'package:equatable/equatable.dart';

/// إشعار داخل التطبيق (جدول notifications).
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.kind = 'event',
    this.matchId,
    this.link,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String kind; // lineup | match | event | status
  final String? matchId;
  final String? link; // الصفحة اللي بيفتحها (match:ID · challenge · totw …) — NotificationRouter

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'].toString(),
    title: (map['title'] ?? '') as String,
    body: (map['body'] ?? '') as String,
    kind: (map['kind'] ?? 'event') as String,
    matchId: map['match_id']?.toString(),
    link: map['link'] as String?,
    createdAt: DateTime.tryParse('${map['created_at']}')?.toLocal() ?? DateTime.now(),
  );

  @override
  List<Object?> get props => [id, title, body, kind, createdAt, matchId, link];
}
