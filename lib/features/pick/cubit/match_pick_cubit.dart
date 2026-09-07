import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/models/pick.dart';
import '../data/picks_repository.dart';

part 'match_pick_state.dart';

/// ViewModel لاختيار تشكيلة ماتش: ٢ من كل فريق + حارس (أي فريق) + ٢ احتياطي + كابتن + نائب.
/// اللاعيبة المتاحة = اللي المدير نزّلهم في تشكيلة الماتش بس.
class MatchPickCubit extends Cubit<MatchPickState> {
  MatchPickCubit(this._players, this._picks, this._lineups, this.match, this.userId)
      : super(const MatchPickState());

  final PlayersRepository _players;
  final PicksRepository _picks;
  final LineupRepository _lineups;
  final GameMatch match;
  final String userId;

  Future<void> load() async {
    emit(const MatchPickState(status: MatchPickStatus.loading));
    try {
      final lineup = await _lineups.fetchForMatch(match.id);
      final ids = lineup.map((l) => l.playerId).toList();
      final players = await _players.fetchByIds(ids);
      final existing = await _picks.fetchForUserMatch(userId, match.id);
      String? cap, vice;
      for (final p in existing) {
        if (p.isCaptain) cap = p.playerId;
        if (p.isVice) vice = p.playerId;
      }
      emit(MatchPickState(
        status: MatchPickStatus.ready,
        players: players,
        sel: {for (final p in existing) p.playerId: p.status},
        captainId: cap,
        viceId: vice,
      ));
    } catch (_) {
      emit(const MatchPickState(status: MatchPickStatus.ready));
    }
  }

  /// إضافة/تغيير حالة لاعب (starting | bench | out).
  void setStatus(String playerId, String status) {
    final sel = Map<String, String>.from(state.sel);
    var cap = state.captainId;
    var vice = state.viceId;
    if (status == 'out') {
      sel.remove(playerId);
    } else {
      sel[playerId] = status;
    }
    if (sel[playerId] != 'starting') {
      if (cap == playerId) cap = null;
      if (vice == playerId) vice = null;
    }
    emit(state.copyWith(sel: sel, captainId: cap, viceId: vice,
        clearCaptain: cap == null, clearVice: vice == null));
  }

  void removePick(String playerId) => setStatus(playerId, 'out');

  void setCaptain(String playerId) {
    if (state.sel[playerId] != 'starting') return;
    final vice = state.viceId == playerId ? null : state.viceId;
    emit(state.copyWith(captainId: playerId, viceId: vice, clearVice: vice == null));
  }

  void setVice(String playerId) {
    if (state.sel[playerId] != 'starting' || state.captainId == playerId) return;
    emit(state.copyWith(viceId: playerId));
  }

  /// تبديل حالة لاعبين (أساسي ↔ احتياطي) — للتبديل مع اللي برا/الاحتياطي.
  void swap(String aId, String bId) {
    final sel = Map<String, String>.from(state.sel);
    final tmp = sel[aId];
    sel[aId] = sel[bId] ?? 'bench';
    sel[bId] = tmp ?? 'bench';
    var cap = state.captainId;
    var vice = state.viceId;
    if (sel[cap] != 'starting') cap = null;
    if (sel[vice] != 'starting') vice = null;
    emit(state.copyWith(sel: sel, captainId: cap, viceId: vice,
        clearCaptain: cap == null, clearVice: vice == null));
  }

  /// بيحفظ بعد التحقّق؛ بيرجّع رسالة خطأ أو null لو نجح.
  Future<String?> save() async {
    if (match.isLocked) return 'اتقفلت التشكيلة — عدّى الديدلاين';
    final starting = state.sel.entries.where((e) => e.value == 'starting').map((e) => e.key).toList();
    final bench = state.sel.entries.where((e) => e.value == 'bench').length;

    final gk = starting.where((id) => state.playerById(id)?.position == 'GK').length;
    final outA = starting.where((id) => state.playerById(id)?.position != 'GK' && state.playerById(id)?.team == match.teamA).length;
    final outB = starting.where((id) => state.playerById(id)?.position != 'GK' && state.playerById(id)?.team == match.teamB).length;

    if (gk != 1) return 'لازم حارس واحد أساسي';
    if (outA != 2) return 'لازم ٢ أساسيين من ${match.teamA}';
    if (outB != 2) return 'لازم ٢ أساسيين من ${match.teamB}';
    if (bench != 2) return 'لازم ٢ احتياطي';
    if (state.captainId == null || !starting.contains(state.captainId)) return 'اختر كابتن من الأساسيين';

    final picks = state.sel.entries
        .map((e) => Pick(
              playerId: e.key,
              status: e.value,
              isCaptain: e.key == state.captainId,
              isVice: e.key == state.viceId,
            ))
        .toList();
    await _picks.savePicks(userId, match.id, picks);
    return null;
  }
}
