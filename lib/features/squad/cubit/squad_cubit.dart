import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/data/models/app_user.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/profile_repository.dart';

part 'squad_state.dart';

/// ViewModel + محرّر تشكيلة المستخدم. بيقرأ ids من profiles.team ويحفظ فيها.
class SquadCubit extends Cubit<SquadState> {
  SquadCubit(this._players, this._profiles) : super(const SquadState());

  final PlayersRepository _players;
  final ProfileRepository _profiles;
  String? _userId;

  bool get _live => SupabaseConfig.isConfigured;

  Future<void> loadForUser(AppUser? user) async {
    _userId = user?.id;
    final ids = user?.team ?? const <String>[];
    if (!_live || ids.isEmpty) {
      emit(const SquadState(status: SquadStatus.loaded));
      return;
    }
    emit(const SquadState(status: SquadStatus.loading));
    try {
      final players = await _players.fetchByIds(ids);
      emit(SquadState(status: SquadStatus.loaded, players: players, captainId: user?.captainId));
    } catch (_) {
      emit(const SquadState(status: SquadStatus.loaded));
    }
  }

  /// بيضيف لاعب؛ بيرجّع رسالة خطأ أو null لو نجح.
  String? addPlayer(Player p) {
    final s = state;
    if (s.players.any((x) => x.id == p.id)) return 'اللاعب موجود في فريقك';
    if (s.count >= 5) return 'الفريق مكتمل — 5 لاعبين';
    if (p.position == 'GK' && s.hasGk) return 'عندك حارس بالفعل';
    if (s.value + p.price > SquadState.budget) return 'مفيش رصيد كافي';
    emit(SquadState(
      status: SquadStatus.loaded,
      players: [...s.players, p],
      captainId: s.captainId,
      dirty: true,
    ));
    return null;
  }

  void removePlayer(String id) {
    final s = state;
    emit(SquadState(
      status: SquadStatus.loaded,
      players: s.players.where((p) => p.id != id).toList(),
      captainId: s.captainId == id ? null : s.captainId, // شيل الكابتن لو اتشال
      dirty: true,
    ));
  }

  void setCaptain(String id) {
    final s = state;
    emit(SquadState(status: SquadStatus.loaded, players: s.players, captainId: id, dirty: true));
  }

  bool contains(String id) => state.players.any((p) => p.id == id);

  /// حفظ التشكيلة. بيرجّع رسالة للمستخدم.
  Future<String> save() async {
    final s = state;
    if (!_live || _userId == null) {
      emit(SquadState(status: SquadStatus.loaded, players: s.players, captainId: s.captainId));
      return 'اتحفظ (وضع تجريبي)';
    }
    emit(SquadState(status: SquadStatus.saving, players: s.players, captainId: s.captainId, dirty: true));
    try {
      await _profiles.updateTeam(_userId!, s.players.map((p) => p.id).toList(), s.captainId);
      emit(SquadState(status: SquadStatus.loaded, players: s.players, captainId: s.captainId));
      return 'تم حفظ الفريق ✓';
    } catch (_) {
      emit(SquadState(status: SquadStatus.loaded, players: s.players, captainId: s.captainId, dirty: true));
      return 'تعذّر الحفظ، حاول تاني';
    }
  }
}
