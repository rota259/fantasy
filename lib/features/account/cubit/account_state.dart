part of 'account_cubit.dart';

enum AccountStatus { initial, loading, loaded }

class AccountState extends Equatable {
  const AccountState({this.status = AccountStatus.initial, this.rank = 0});

  final AccountStatus status;
  final int rank;

  @override
  List<Object?> get props => [status, rank];
}
