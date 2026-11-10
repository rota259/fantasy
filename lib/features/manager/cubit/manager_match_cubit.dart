import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/app_mode.dart';
import '../../../core/supabase/db_error.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/match_live.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../../integrity/data/integrity_repository.dart';
import '../data/lineup_repository.dart';

part 'manager_match_state.dart';
part 'manager_match_cubit_actions.dart';
part 'manager_match_cubit_actions2.dart';

/// ViewModel لصفحة إدارة ماتش (المدير يدخّل التشكيلة والأحداث).
class ManagerMatchCubit extends Cubit<ManagerMatchState> {
  // emit محمي (protected) — الأجزاء المنقولة لملفات تانية بتغيّر الحالة من هنا
  void _emit(ManagerMatchState s) => emit(s);

  ManagerMatchCubit(this._players, this._events, this._lineups, this._integrity, this.match)
    : super(ManagerMatchState(format: match.format));

  final IntegrityRepository _integrity;
  final PlayersRepository _players;
  final EventsRepository _events;
  final LineupRepository _lineups;
  final GameMatch match;

  /// خماسي (٥) أو سداسي (٦) — بيتحفظ مع التشكيلة.
  void setFormat(int f) => emit(state.copyWith(format: f));

  /// اللي في الملعب دلوقتي (الأساسيين + اللي نزلوا − اللي طلعوا − الأحمر).
  Set<String> get onPitch => MatchLive.onPitch(state.lineup, state.events);

  /// الاحتياطي اللي لسه منزلش.
  Set<String> get benchLeft => MatchLive.benchLeft(state.lineup, state.events);

  /// النتيجة من الأهداف المسجّلة (نفس السيرفر).
  ({int a, int b}) get score =>
      MatchLive.score(match.teams, state.events, {for (final p in state.players) p.id: p.team});

  /// بيرجّع null لو اتسجّل، أو رسالة الخطأ. التبديل: [playerId] اللي نزل و[otherPlayerId] اللي طلع.
  Future<String?> addEvent(String playerId, String type, int? minute, {String? otherPlayerId}) async {
    if (!state.lineup.containsKey(playerId)) return 'اللاعب لازم يكون في التشكيلة (واحفظها الأول)';
    if (!kTestMode && DateTime.now().isBefore(match.dateTime.subtract(const Duration(minutes: 15)))) {
      return 'الأحداث بتتسجّل لما الماتش يبدأ';
    }
    try {
      await _events.addEvent(
        matchId: match.id,
        playerId: playerId,
        type: type,
        minute: minute,
        otherPlayerId: otherPlayerId,
      );
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر تسجيل الحدث');
    }
    // إشعار الحدث لمتابعين الماتش بيتبعت من الداتابيز لوحده
    await _reloadEvents();
    return null;
  }

  Future<void> removeEvent(String id) async {
    await _events.deleteEvent(id);
    await _reloadEvents();
  }

  Future<void> _reloadEvents() async {
    final events = await _events.fetchByMatch(match.id);
    emit(state.copyWith(events: events));
  }

  Player? player(String id) => _player(id);
}
