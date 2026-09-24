import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../players/data/availability.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';

part 'manager_players_state.dart';

/// ViewModel لإدارة اللاعيبة (المدير يضيف/يحذف).
class ManagerPlayersCubit extends Cubit<ManagerPlayersState> {
  ManagerPlayersCubit(this._repo) : super(const ManagerPlayersState());

  final PlayersRepository _repo;

  Future<void> load() async {
    emit(const ManagerPlayersState(status: ManagerPlayersStatus.loading));
    try {
      final players = await _repo.fetchAll();
      emit(ManagerPlayersState(status: ManagerPlayersStatus.ready, players: players));
    } catch (_) {
      emit(const ManagerPlayersState(status: ManagerPlayersStatus.ready));
    }
  }

  Future<void> add({
    required String name,
    required String team,
    required String position,
  }) async {
    await _repo.addPlayer(name: name, team: team, position: position);
    await load();
  }

  /// (مدير) تعديل بيانات لاعب. بيرجّع رسالة خطأ أو null.
  Future<String?> update(String id, {required String name, required String team, required String position}) async {
    try {
      await _repo.updatePlayer(id, name: name, team: team, position: position);
      await load();
      return null;
    } catch (e) {
      return 'فشل التعديل: $e';
    }
  }

  /// (مدير) تحديث حالة اللاعب (جاهز/مصاب/…) وسببها + إشعار لكل اليوزرز.
  Future<void> setAvailability(String id, String availability, String? news) async {
    await _repo.setAvailability(id, availability, news);
    await _notifyStatus(id, availability, news);
    await load();
  }

  /// إشعار داخل التطبيق بحالة اللاعب الجديدة (يظهر فورًا للكل عبر realtime).
  Future<void> _notifyStatus(String id, String availability, String? news) async {
    final name = _playerName(id);
    final body = (news != null && news.isNotEmpty) ? news : 'تحديث حالة اللاعب';
    try {
      await SupabaseService.table('notifications').insert({
        'title': '${Availability.label(availability)} — $name 🩺',
        'body': body,
        'kind': 'status',
      });
    } catch (_) {}
  }

  String _playerName(String id) {
    for (final p in state.players) {
      if (p.id == id) return p.name;
    }
    return '';
  }

  /// بيرجّع null لو نجح، أو رسالة الخطأ لو فشل.
  Future<String?> remove(String id) async {
    try {
      final n = await _repo.deletePlayer(id);
      if (n == 0) {
        return 'الحذف محتاج صلاحية مدير — تأكد إن حسابك Role = manager';
      }
      await load();
      return null;
    } catch (e) {
      return 'فشل الحذف: $e';
    }
  }
}
