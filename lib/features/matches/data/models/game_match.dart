import 'package:equatable/equatable.dart';

/// ماتش/جولة (جدول matches). اسمها GameMatch عشان Match محجوزة في Dart.
/// الأوقات بتتخزّن UTC في السيرفر وبتتعرض بتوقيت الجهاز.
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
    this.finishedAt,
    this.isChallenge = false,
    this.motmPlayerId,
    this.motmDone = false,
    this.organizerId,
    this.reviewStatus = 'open',
    this.reviewDue,
    this.flags = const [],
  });

  final String id;
  final DateTime dateTime;
  final List<String> teams;
  final int week;
  final String status; // 'upcoming' أو 'finished'
  final int fdr; // صعوبة الماتش 1..5
  final int? scoreA;
  final int? scoreB;
  final DateTime? finishedAt; // وقت ما المدير قفل الماتش
  final bool isChallenge; // تحدّي الجولة (توقّع النتيجة)
  final String? motmPlayerId; // رجل المباراة (تصويت الجمهور)
  final bool motmDone;
  final String? organizerId; // المنظّم (null = الأدمن)
  final String reviewStatus; // open · pending (مستني تأكيد) · approved · disputed (اعتراض) · void (اتلغى)
  final DateTime? reviewDue; // بيتعتمد لوحده بعدها لو مفيش علامات
  final List<String> flags; // علامات الغرابة (MatchFlags)

  /// مدة تقييم الجمهور بعد نهاية الماتش.
  static const ratingWindow = Duration(hours: 24);

  bool get isFinished => status == 'finished';

  /// نقطه اتحسبت في الإجمالي والترتيب.
  bool get isApproved => reviewStatus == 'approved';

  /// خلص ولسه مستني التأكيد أو الحكم — النقط "مبدئية".
  bool get isProvisional => isFinished && (reviewStatus == 'pending' || reviewStatus == 'disputed');
  bool get isVoid => reviewStatus == 'void';

  /// النتيجة كنص، مثلًا "3 - 2" (فاضية لو الماتش لسه).
  String get scoreText => (scoreA == null || scoreB == null) ? '' : '$scoreA - $scoreB';
  String get teamA => teams.isNotEmpty ? teams[0] : '';
  String get teamB => teams.length > 1 ? teams[1] : '';

  /// الديدلاين = ميعاد الماتش ناقص ساعة.
  DateTime get deadline => dateTime.subtract(const Duration(hours: 1));
  bool get isLocked => DateTime.now().isAfter(deadline);
  bool get hasStarted => DateTime.now().isAfter(dateTime);

  /// تقييم اللاعيبة مفتوح (٢٤ ساعة بعد النهاية ولسه رجل المباراة ماتعلنش).
  bool get ratingOpen =>
      isFinished && !motmDone && finishedAt != null && DateTime.now().isBefore(finishedAt!.add(ratingWindow));

  static DateTime? _date(Object? v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory GameMatch.fromMap(Map<String, dynamic> map) => GameMatch(
    id: map['id'].toString(),
    dateTime: _date(map['date_time'])!,
    teams: List<String>.from(map['teams'] ?? const []),
    week: (map['week'] ?? 0) as int,
    status: (map['status'] ?? 'upcoming') as String,
    fdr: (map['fdr'] ?? 3) as int,
    scoreA: map['score_a'] as int?,
    scoreB: map['score_b'] as int?,
    finishedAt: _date(map['finished_at']),
    isChallenge: (map['is_challenge'] ?? false) as bool,
    motmPlayerId: map['motm_player_id']?.toString(),
    motmDone: (map['motm_done'] ?? false) as bool,
    organizerId: map['organizer_id']?.toString(),
    reviewStatus: (map['review_status'] ?? 'open') as String,
    reviewDue: _date(map['review_due']),
    flags: List<String>.from(map['flags'] ?? const []),
  );

  /// للكتابة: الوقت UTC عشان السيرفر يفهمه صح (من غير فرق التوقيت).
  static String dbTime(DateTime d) => d.toUtc().toIso8601String();

  @override
  List<Object?> get props => [
    id,
    dateTime,
    teams,
    week,
    status,
    fdr,
    scoreA,
    scoreB,
    finishedAt,
    isChallenge,
    motmPlayerId,
    motmDone,
    organizerId,
    reviewStatus,
    reviewDue,
    flags,
  ];
}
