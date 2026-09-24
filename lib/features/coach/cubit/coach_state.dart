part of 'coach_cubit.dart';

enum CoachStatus { initial, loading, ready }

class CoachState extends Equatable {
  const CoachState({this.status = CoachStatus.initial, this.report});

  final CoachStatus status;
  final CoachReport? report;

  bool get isLoading => status == CoachStatus.loading;

  @override
  List<Object?> get props => [status, report];
}
