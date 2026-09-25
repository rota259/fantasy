import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../matches/data/models/game_match.dart';
import '../data/challenge_repository.dart';
import '../data/models/prediction.dart';

part 'challenge_state.dart';

/// ViewModel تحدّي الجولة: الماتش + توقّعي + النتيجة بعد الماتش.
class ChallengeCubit extends Cubit<ChallengeState> {
  ChallengeCubit(this._repo, this.userId) : super(const ChallengeState());

  final ChallengeRepository _repo;
  final String? userId;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const ChallengeState(loading: false));
      return;
    }
    await _fetch();
    // المدير أعلن تحدّي جديد أو قفل الماتش → يتحدّث لوحده
    _sub ??= liveTable('matches', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final m = await _repo.current();
      final (mine, summary) = await (
        m == null ? Future<Prediction?>.value() : _repo.mine(m.id, userId!),
        (m != null && m.isFinished)
            ? _repo.summary(m.id).then<({int total, int correct})?>((v) => v)
            : Future<({int total, int correct})?>.value(),
      ).wait;
      if (!isClosed) emit(ChallengeState(loading: false, match: m, mine: mine, summary: summary));
    } catch (_) {
      if (!isClosed) emit(const ChallengeState(loading: false));
    }
  }

  /// بيرجّع رسالة خطأ أو null.
  Future<String?> predict(int a, int b) async {
    final m = state.match;
    if (m == null || userId == null) return 'مفيش تحدّي دلوقتي';
    if (m.isLocked) return 'التوقّع اتقفل';
    try {
      await _repo.predict(m.id, userId!, a, b);
      emit(
        state.copyWith(
          mine: Prediction(matchId: m.id, scoreA: a, scoreB: b),
        ),
      );
      return null;
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر حفظ التوقّع');
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
