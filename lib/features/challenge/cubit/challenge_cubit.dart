import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/live_hub.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../matches/data/models/game_match.dart';
import '../data/challenge_repository.dart';
import '../data/models/prediction.dart';

part 'challenge_state.dart';

/// ViewModel تحدّي الجولة: تحدّيات منطقتي (واحد لكل مدير) + توقّعاتي + النتيجة بعد الماتش.
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
    // مدير أعلن تحدّي جديد أو قفل ماتش → يتحدّث لوحده
    _sub ??= LiveHub.on('matches', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final list = await _repo.challenges();
      final (mine, summaries) = await (
        _repo.mine([for (final m in list) m.id], userId!),
        Future.wait([
          for (final m in list)
            m.isFinished
                ? _repo.summary(m.id).then<({int total, int correct})?>((v) => v)
                : Future<({int total, int correct})?>.value(),
        ]),
      ).wait;
      if (isClosed) return;
      emit(
        ChallengeState(
          loading: false,
          items: [for (final (i, m) in list.indexed) ChallengeItem(match: m, mine: mine[m.id], summary: summaries[i])],
        ),
      );
    } catch (_) {
      if (!isClosed) emit(const ChallengeState(loading: false));
    }
  }

  /// بيرجّع رسالة خطأ أو null.
  Future<String?> predict(GameMatch m, int a, int b) async {
    if (userId == null) return 'سجّل دخول الأول';
    if (m.isLocked) return 'التوقّع اتقفل';
    try {
      await _repo.predict(m.id, userId!, a, b);
      final p = Prediction(matchId: m.id, scoreA: a, scoreB: b);
      emit(
        ChallengeState(
          loading: false,
          items: [for (final it in state.items) it.match.id == m.id ? it.withMine(p) : it],
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
