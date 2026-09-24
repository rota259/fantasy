part of 'poll_cubit.dart';

enum PollStatus { initial, loading, ready }

class PollState extends Equatable {
  const PollState({this.status = PollStatus.initial, this.view});

  final PollStatus status;
  final PollView? view;

  bool get isLoading => status == PollStatus.loading;

  @override
  List<Object?> get props => [status, view];
}
