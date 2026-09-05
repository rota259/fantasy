part of 'challenge_cubit.dart';

enum ChallengeStatus { initial, loading, loaded }

class ChallengeState extends Equatable {
  const ChallengeState({this.status = ChallengeStatus.initial, this.result});

  final ChallengeStatus status;
  final ChallengeResult? result;

  bool get isLoading => status == ChallengeStatus.loading;

  @override
  List<Object?> get props => [status, result];
}
