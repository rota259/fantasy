part of 'coach_cubit.dart';

enum CoachStatus { initial, loading, loaded }

class CoachState extends Equatable {
  const CoachState({this.status = CoachStatus.initial, this.advice});

  final CoachStatus status;
  final CoachAdvice? advice;

  bool get isLoading => status == CoachStatus.loading;

  @override
  List<Object?> get props => [status, advice];
}
