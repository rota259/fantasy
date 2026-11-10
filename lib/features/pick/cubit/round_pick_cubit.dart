import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/utils/perf.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../teams/data/team.dart';
import '../../teams/data/teams_repository.dart';
import '../../week/data/week_window.dart';
import '../data/models/pick.dart';
import '../data/models/round_locks.dart';
import '../data/picks_repository.dart';

part 'round_pick_state.dart';
part 'round_pick_save.dart';

/// ViewModel تشكيلة الجولة: ٧ لاعيبة من أي فرق في منطقتك — ٥ أساسي (حارس واحد) + ٢ احتياطي
/// + كابتن وكابتن بديل (الاتنين لازم عشان تتحفظ). المدير ميقدرش يختار من فرقه.
/// كل لاعب بيتقفل قبل ماتشه بساعة: أي تغيير يلمس لاعب متقفل (دخول · خروج · مكانه · الكابتن) بيتجاهل.
class RoundPickCubit extends Cubit<RoundPickState> {
  RoundPickCubit(this._players, this._picks, this._teams, this.window, this.userId, {this.isOrganizer = false})
    : super(const RoundPickState());

  final PlayersRepository _players;
  final PicksRepository _picks;
  final TeamsRepository _teams;
  final WeekWindow window;
  final String userId;
  final bool isOrganizer;

  // emit محمي (protected) — الحفظ في ملف تاني بيغيّر الحالة من هنا
  void _emit(RoundPickState s) => emit(s);

  Future<void> load() async {
    emit(const RoundPickState());
    try {
      final (players, all, mine, locks) = await timed(
        'round pick',
        () => (
          _players.fetchMyZone(),
          _picks.fetchAllRounds(userId),
          isOrganizer ? _teams.mine(userId) : Future.value(const <Team>[]),
          _picks.roundLocks(window.cutoff).catchError((_) => const RoundLocks()),
        ).wait,
      );
      final ownTeams = {for (final t in mine) t.name};
      final available = players.where((p) => p.team.isNotEmpty && !ownTeams.contains(p.team)).toList();
      final ids = {for (final p in available) p.id};

      // تشكيلة الجولة دي، ولو مفيش: آخر تشكيلة قبلها كبداية
      var picks = all[window.cutoff] ?? const <Pick>[];
      final saved = picks.isNotEmpty;
      if (!saved) {
        final earlier = all.keys.where((k) => k.isBefore(window.cutoff)).toList()..sort();
        if (earlier.isNotEmpty) picks = all[earlier.last]!;
      }
      picks = picks.where((p) => ids.contains(p.playerId)).toList(); // اللي مبقاش متاح يطلع
      emit(
        RoundPickState(
          status: RoundPickStatus.ready,
          players: available,
          sel: {for (final p in picks) p.playerId: p.status},
          captainId: picks.where((p) => p.isCaptain).firstOrNull?.playerId,
          viceId: picks.where((p) => p.isVice).firstOrNull?.playerId,
          saved: saved,
          fromLastRound: !saved && picks.isNotEmpty,
          locks: locks,
        ),
      );
    } catch (_) {
      emit(const RoundPickState(status: RoundPickStatus.ready));
    }
  }

  /// إضافة/تغيير حالة لاعب (starting | bench | out).
  void setStatus(String playerId, String status) {
    if (state.isLocked(playerId)) return;
    final sel = Map<String, String>.from(state.sel);
    if (status == 'out') {
      sel.remove(playerId);
    } else {
      sel[playerId] = status;
    }
    _emitSel(sel);
  }

  void removePick(String playerId) => setStatus(playerId, 'out');

  void setCaptain(String playerId) {
    if (state.sel[playerId] != 'starting' || _frozen([playerId, state.captainId])) return;
    final vice = state.viceId == playerId ? null : state.viceId;
    emit(state.copyWith(captainId: playerId, viceId: vice, clearVice: vice == null));
  }

  void setVice(String playerId) {
    if (state.sel[playerId] != 'starting' || state.captainId == playerId || _frozen([playerId, state.viceId])) return;
    emit(state.copyWith(viceId: playerId));
  }

  /// تبديل حالة لاعبين (أساسي ↔ احتياطي).
  void swap(String aId, String bId) {
    if (_frozen([aId, bId])) return;
    final sel = Map<String, String>.from(state.sel);
    final tmp = sel[aId];
    sel[aId] = sel[bId] ?? 'bench';
    sel[bId] = tmp ?? 'bench';
    _emitSel(sel);
  }

  /// فيه لاعب متقفل في التغيير ده؟
  bool _frozen(Iterable<String?> ids) => ids.any((id) => id != null && state.isLocked(id));

  /// الكابتن والبديل لازم يفضلوا أساسيين.
  void _emitSel(Map<String, String> sel) {
    final cap = sel[state.captainId] == 'starting' ? state.captainId : null;
    final vice = sel[state.viceId] == 'starting' ? state.viceId : null;
    emit(state.copyWith(sel: sel, captainId: cap, viceId: vice, clearCaptain: cap == null, clearVice: vice == null));
  }
}
