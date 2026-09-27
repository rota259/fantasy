import 'package:equatable/equatable.dart';

/// طلب مدير منطقة يضيف ماتش بعد ديدلاين الجولة (late_match_requests) — الأدمن بيوافق أو يرفض.
class LateMatchRequest extends Equatable {
  const LateMatchRequest({
    required this.id,
    required this.teams,
    required this.dateTime,
    this.organizerName = '',
    this.phone,
    this.note,
  });

  final String id;
  final List<String> teams;
  final DateTime dateTime;
  final String organizerName;
  final String? phone;
  final String? note;

  factory LateMatchRequest.fromMap(Map<String, dynamic> map) => LateMatchRequest(
    id: map['id'].toString(),
    teams: ((map['teams'] as List?) ?? const []).map((e) => e.toString()).toList(),
    dateTime: DateTime.parse(map['date_time'] as String).toLocal(),
    organizerName: (map['organizer_name'] ?? '') as String,
    phone: map['phone'] as String?,
    note: map['note'] as String?,
  );

  @override
  List<Object?> get props => [id, teams, dateTime, organizerName, phone, note];
}
