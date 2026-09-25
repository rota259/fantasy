import 'package:equatable/equatable.dart';

/// الموسم: المدير بيحدد البداية ونص الموسم والنهاية (الكروت بتتحسب بالنصّين).
class Season extends Equatable {
  const Season({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.midAt,
    required this.endsAt,
  });

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime midAt;
  final DateTime endsAt;

  bool get isValid => startsAt.isBefore(midAt) && midAt.isBefore(endsAt);

  bool isCurrent([DateTime? now]) {
    final n = now ?? DateTime.now();
    return !n.isBefore(startsAt) && n.isBefore(endsAt);
  }

  /// نص الموسم لوقت معيّن (١ أو ٢).
  int halfAt(DateTime t) => t.isBefore(midAt) ? 1 : 2;

  static DateTime _d(Object v) => DateTime.parse(v.toString()).toLocal();

  factory Season.fromMap(Map<String, dynamic> m) => Season(
    id: m['id'].toString(),
    name: (m['name'] ?? '') as String,
    startsAt: _d(m['starts_at']),
    midAt: _d(m['mid_at']),
    endsAt: _d(m['ends_at']),
  );

  Map<String, dynamic> toWrite() => {
    'name': name,
    'starts_at': startsAt.toUtc().toIso8601String(),
    'mid_at': midAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [id, name, startsAt, midAt, endsAt];
}
