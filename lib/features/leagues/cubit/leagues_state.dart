part of 'leagues_cubit.dart';

enum LeaguesStatus { initial, loading, loaded }

class LeaguesState extends Equatable {
  const LeaguesState({
    this.status = LeaguesStatus.initial,
    this.globalRank = 0,
    this.myLeagues = const [],
    this.standings = const [],
    this.selectedLeagueId,
    this.badges = const {},
    this.hasMore = false,
  });

  final LeaguesStatus status;
  final int globalRank;
  final List<MyLeague> myLeagues;
  final List<LeagueStanding> standings;
  final String? selectedLeagueId;
  final Map<String, List<UserBadge>> badges; // userId → شاراته (الأعلى أولًا)
  final bool hasMore; // فيه صفحات تانية من الترتيب

  bool get isLoading => status == LeaguesStatus.loading;
  bool get hasData => myLeagues.isNotEmpty;

  MyLeague? get selected {
    for (final m in myLeagues) {
      if (m.league.id == selectedLeagueId) return m;
    }
    return myLeagues.firstOrNull;
  }

  LeaguesState copyWith({
    List<LeagueStanding>? standings,
    String? selectedLeagueId,
    Map<String, List<UserBadge>>? badges,
    bool? hasMore,
  }) {
    return LeaguesState(
      status: status,
      globalRank: globalRank,
      myLeagues: myLeagues,
      standings: standings ?? this.standings,
      selectedLeagueId: selectedLeagueId ?? this.selectedLeagueId,
      badges: badges ?? this.badges,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [status, globalRank, myLeagues, standings, selectedLeagueId, badges, hasMore];
}
