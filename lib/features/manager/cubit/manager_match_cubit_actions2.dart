part of 'manager_match_cubit.dart';

extension ManagerMatchCubitSections2 on ManagerMatchCubit {
  String playerName(String id) {
    for (final p in state.players) {
      if (p.id == id) return p.name;
    }
    return '—';
  }
}
