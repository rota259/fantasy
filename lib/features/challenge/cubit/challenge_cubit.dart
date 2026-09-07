import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/data/models/app_user.dart';
import '../../leagues/data/leagues_repository.dart';

part 'challenge_state.dart';

/// نتيجة المواجهة (نقاط إجمالية).
class ChallengeResult {
  const ChallengeResult({
    required this.meName,
    required this.mePoints,
    required this.oppName,
    required this.oppPoints,
  });

  final String meName;
  final int mePoints;
  final String oppName;
  final int oppPoints;

  bool get meWins => mePoints >= oppPoints;
}

/// ViewModel للتحدّي — يقارن نقاطك بأقرب خصم في دوريك (من الترتيب).
class ChallengeCubit extends Cubit<ChallengeState> {
  ChallengeCubit(this._leagues) : super(const ChallengeState());

  final LeaguesRepository _leagues;

  Future<void> load(AppUser? me) async {
    if (!SupabaseConfig.isConfigured || me == null) {
      emit(const ChallengeState(status: ChallengeStatus.loaded));
      return;
    }
    emit(const ChallengeState(status: ChallengeStatus.loading));
    try {
      final leagues = await _leagues.myLeagues(me.id);
      if (leagues.isEmpty) return emit(const ChallengeState(status: ChallengeStatus.loaded));

      final standings = await _leagues.standings(leagues.first.league.id);
      final rivals = standings.where((s) => s.userId != me.id).toList();
      if (rivals.isEmpty) return emit(const ChallengeState(status: ChallengeStatus.loaded));

      final myPoints = standings
          .where((s) => s.userId == me.id)
          .map((s) => s.points)
          .fold<int>(me.totalPoints, (_, p) => p);

      emit(ChallengeState(
        status: ChallengeStatus.loaded,
        result: ChallengeResult(
          meName: me.name,
          mePoints: myPoints,
          oppName: rivals.first.name,
          oppPoints: rivals.first.points,
        ),
      ));
    } catch (_) {
      emit(const ChallengeState(status: ChallengeStatus.loaded));
    }
  }
}
