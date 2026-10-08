part of 'home_cubit.dart';

enum HomeStatus { loading, ready }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.points = 0,
    this.nextMatch,
    this.star,
    this.starFromPrevious = false,
    this.starRound,
    this.weekFinal = false,
    this.weekLabel = '',
    this.toRate = const [],
    this.tieOpen = false,
    this.toReview = const [],
    this.openRound,
    this.roundSaved = true,
  });

  final HomeStatus status;
  final int points;
  final GameMatch? nextMatch;
  final WeekPlayer? star; // نجم الجولة (أعلى نقط)
  final bool starFromPrevious; // الجولة الجديدة لسه فاضية → نجم اللي فاتت
  final WeekWindow? starRound; // جولة النجم (لتفاصيله)
  final bool weekFinal; // الجولة خلصت (الترتيب نهائي)
  final String weekLabel;
  final List<GameMatch> toRate; // ماتشات التقييم فيها مفتوح
  final bool tieOpen; // فيه تصويت تعادل على تشكيلة الجولة
  final List<PendingReview> toReview; // ماتشات لعبت فيها ومستنية تأكيدي
  final WeekWindow? openRound; // الجولة اللي التشكيلات مفتوحة ليها
  final bool roundSaved; // حفظت تشكيلتها

  bool get isLoading => status == HomeStatus.loading;

  @override
  List<Object?> get props => [
    status,
    points,
    nextMatch,
    star,
    starFromPrevious,
    starRound,
    weekFinal,
    weekLabel,
    toRate,
    tieOpen,
    toReview,
    openRound,
    roundSaved,
  ];
}
