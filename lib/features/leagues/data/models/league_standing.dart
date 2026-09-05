import 'package:equatable/equatable.dart';

import 'league.dart';

/// صف في ترتيب الدوري.
class LeagueStanding extends Equatable {
  const LeagueStanding({
    required this.rank,
    required this.userId,
    required this.name,
    required this.points,
  });

  final int rank;
  final String userId;
  final String name;
  final int points;

  @override
  List<Object?> get props => [rank, userId, name, points];
}

/// دوري المستخدم مع ترتيبه فيه (لصفوف قائمة الدوريات).
class MyLeague extends Equatable {
  const MyLeague({required this.league, required this.userRank});

  final League league;
  final int userRank;

  @override
  List<Object?> get props => [league, userRank];
}
