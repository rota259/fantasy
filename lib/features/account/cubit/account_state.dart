part of 'account_cubit.dart';

enum AccountStatus { initial, loading, loaded }

class AccountState extends Equatable {
  const AccountState({this.status = AccountStatus.initial, this.rank = 0, this.bestMatch = 0, this.linkedPlayer});

  final AccountStatus status;
  final int rank;
  final int bestMatch; // أعلى نقط في جولة واحدة
  final Player? linkedPlayer; // لو اليوزر لاعب موثّق

  @override
  List<Object?> get props => [status, rank, bestMatch, linkedPlayer];
}
