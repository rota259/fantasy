part of 'home_cubit.dart';

enum HomeStatus { loading, ready }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.points = 0,
    this.nextMatch,
    this.star,
    this.starFromPrevious = false,
    this.weekFinal = false,
    this.weekLabel = '',
    this.toRate = const [],
    this.tieOpen = false,
  });

  final HomeStatus status;
  final int points;
  final GameMatch? nextMatch;
  final WeekPlayer? star; // نجم الجولة (أعلى نقط)
  final bool starFromPrevious; // الجولة الجديدة لسه فاضية → نجم اللي فاتت
  final bool weekFinal; // الجولة قفلت (الجمعة من 4 الفجر لـ 12 بالليل)
  final String weekLabel;
  final List<GameMatch> toRate; // ماتشات التقييم فيها مفتوح
  final bool tieOpen; // فيه تصويت تعادل على تشكيلة الجولة

  bool get isLoading => status == HomeStatus.loading;

  @override
  List<Object?> get props => [status, points, nextMatch, star, starFromPrevious, weekFinal, weekLabel, toRate, tieOpen];
}
