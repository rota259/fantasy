import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/live_hub.dart';
import '../../matches/data/models/game_match.dart';
import '../data/models/tournament.dart';
import '../data/tournaments_repository.dart';

/// حالة شاشة بطولة: كل حاجة مع بعض (البطولة · الفرق · الماتشات · الترتيب · الشجرة · الجوايز · التوقعات).
class TournamentState {
  const TournamentState({
    this.loading = true,
    this.tournament,
    this.teams = const [],
    this.matches = const [],
    this.table = const [],
    this.bracket = const [],
    this.awards = const [],
    this.myPick,
    this.picks = const {},
  });

  final bool loading;
  final Tournament? tournament;
  final List<TournamentTeam> teams;
  final List<GameMatch> matches;
  final List<TournamentRow> table;
  final List<BracketSlot> bracket;
  final List<TournamentAward> awards;
  final String? myPick; // توقّعي للبطل
  final Map<String, int> picks; // كام واحد توقّع كل فريق

  List<TournamentTeam> get approved => [
    for (final t in teams)
      if (t.isApproved) t,
  ];
  List<TournamentTeam> get pending => [
    for (final t in teams)
      if (t.isPending) t,
  ];

  /// التوقّع مفتوح لحد أول ماتش.
  bool get predictOpen =>
      tournament != null && !tournament!.isFinished && !matches.any((m) => !m.dateTime.isAfter(DateTime.now()));

  /// المجموعات خلصت ولسه خروج المغلوب مبدأش.
  bool get groupsDone =>
      tournament?.format == 'groups' && bracket.isEmpty && matches.isNotEmpty && matches.every((m) => m.isFinished);
}

/// ViewModel البطولة — بيتحدّث لايف مع أي ماتش يتغيّر.
class TournamentCubit extends Cubit<TournamentState> {
  TournamentCubit(this._repo, this.id, this.userId) : super(const TournamentState());

  final TournamentsRepository _repo;
  final String id;
  final String? userId;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    await _fetch();
    _sub ??= LiveHub.on('matches', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final (t, teams, matches, table, bracket, awards, preds) = await (
        _repo.byId(id),
        _repo.teams(id),
        _repo.matches(id),
        _repo.standings(id),
        _repo.bracket(id),
        _repo.awards(id),
        _repo.predictions(id, userId ?? ''),
      ).wait;
      if (isClosed) return;
      emit(
        TournamentState(
          loading: false,
          tournament: t,
          teams: teams,
          matches: matches,
          table: table,
          bracket: bracket,
          awards: awards,
          myPick: preds.$1,
          picks: preds.$2,
        ),
      );
    } catch (_) {
      if (!isClosed && state.loading) emit(const TournamentState(loading: false));
    }
  }

  /// بيرجّع رسالة خطأ أو null — وبعدها يحدّث.
  Future<String?> _run(Future<void> Function() action) async {
    try {
      await action();
      await _fetch();
      return null;
    } catch (e) {
      return dbMessage(e);
    }
  }

  Future<String?> addTeam(String team) => _run(() => _repo.addTeam(id, team));
  Future<String?> requestTeam(String team, String phone, String? note) =>
      _run(() => _repo.requestTeam(id, team, phone, note));
  Future<String?> reviewTeam(String team, bool ok) => _run(() => _repo.reviewTeam(id, team, ok));
  Future<String?> draw() => _run(() => _repo.draw(id));
  Future<String?> startKnockout() => _run(() => _repo.startKnockout(id));
  Future<String?> setWinner(String matchId, String team) => _run(() => _repo.setWinner(matchId, team));
  Future<String?> predict(String team) => _run(() => _repo.predict(id, team));

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
