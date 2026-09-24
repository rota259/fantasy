import 'package:equatable/equatable.dart';

/// ماتش/جولة (جدول matches). اسمها GameMatch عشان Match محجوزة في Dart.
class GameMatch extends Equatable {
  const GameMatch({
    required this.id,
    required this.dateTime,
    required this.teams,
    required this.week,
    this.status = 'upcoming',
    this.fdr = 3,
    this.scoreA,
    this.scoreB,
  });

  final String id;
  final DateTime dateTime;
  final List<String> teams;
  final int week;
  final String status; // 'upcoming' أو 'finished'
  final int fdr; // صعوبة الماتش 1..5
  final int? scoreA; // أهداف الفريق الأول (بعد ما الماتش يخلص)
  final int? scoreB;

  bool get isFinished => status == 'finished';

  /// النتيجة كنص، مثلًا "3 - 2" (فاضية لو الماتش لسه).
  String get scoreText => (scoreA == null || scoreB == null) ? '' : '$scoreA - $scoreB';
  String get teamA => teams.isNotEmpty ? teams[0] : '';
  String get teamB => teams.length > 1 ? teams[1] : '';

  /// الديدلاين = ميعاد الماتش ناقص ساعة.
  DateTime get deadline => dateTime.subtract(const Duration(hours: 1));
  bool get isLocked => DateTime.now().isAfter(deadline);

  factory GameMatch.fromMap(Map<String, dynamic> map) => GameMatch(
        id: map['id'].toString(),
        dateTime: DateTime.parse(map['date_time'] as String),
        teams: List<String>.from(map['teams'] ?? const []),
        week: (map['week'] ?? 0) as int,
        status: (map['status'] ?? 'upcoming') as String,
        fdr: (map['fdr'] ?? 3) as int,
        scoreA: map['score_a'] as int?,
        scoreB: map['score_b'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'date_time': dateTime.toIso8601String(),
        'teams': teams,
        'week': week,
        'status': status,
        'fdr': fdr,
      };

  @override
  List<Object?> get props => [id, dateTime, teams, week, status, fdr, scoreA, scoreB];
}
