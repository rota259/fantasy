import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/match_model.dart';
import 'package:fantasy_5omasi/models/event_model.dart';
import 'package:fantasy_5omasi/repositories/match_repository.dart';

part 'match_state.dart';

class MatchCubit extends Cubit<MatchState> {
  final MatchRepository matchRepository;

  MatchCubit(this.matchRepository) : super(MatchInitial());

  Future<void> fetchMatches() async {
    emit(MatchLoading());
    try {
      final matches = await matchRepository.getAllMatches();
      emit(MatchLoaded(matches));
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> addMatch(MatchModel match) async {
    emit(MatchLoading());
    try {
      await matchRepository.addMatch(match);
      await fetchMatches();
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    emit(MatchLoading());
    try {
      await matchRepository.updateMatchStatus(matchId, status);
      await fetchMatches();
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }

  Future<void> addEvents(String matchId, List<EventModel> events) async {
    emit(MatchLoading());
    try {
      await matchRepository.addMatchEvents(matchId, events);
      await fetchMatches();
    } catch (e) {
      emit(MatchError(e.toString()));
    }
  }
}
