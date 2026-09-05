part of 'leagues_cubit.dart';

enum LeaguesStatus { initial, loading, loaded }

class LeaguesState extends Equatable {
  const LeaguesState({
    this.status = LeaguesStatus.initial,
    this.globalRank = 0,
    this.myLeagues = const [],
    this.standings = const [],
    this.selectedLeagueId,
  });

  final LeaguesStatus status;
  final int globalRank;
  final List<MyLeague> myLeagues;
  final List<LeagueStanding> standings;
  final String? selectedLeagueId;

  bool get isLoading => status == LeaguesStatus.loading;
  bool get hasData => myLeagues.isNotEmpty;

  LeaguesState copyWith({
    LeaguesStatus? status,
    int? globalRank,
    List<MyLeague>? myLeagues,
    List<LeagueStanding>? standings,
    String? selectedLeagueId,
  }) {
    return LeaguesState(
      status: status ?? this.status,
      globalRank: globalRank ?? this.globalRank,
      myLeagues: myLeagues ?? this.myLeagues,
      standings: standings ?? this.standings,
      selectedLeagueId: selectedLeagueId ?? this.selectedLeagueId,
    );
  }

  @override
  List<Object?> get props => [status, globalRank, myLeagues, standings, selectedLeagueId];
}
