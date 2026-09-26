part of 'round_pick_cubit.dart';

enum RoundPickStatus { loading, ready }

class RoundPickState extends Equatable {
  const RoundPickState({
    this.status = RoundPickStatus.loading,
    this.players = const [],
    this.sel = const {},
    this.captainId,
    this.viceId,
    this.saved = false,
    this.fromLastRound = false,
  });

  static const starters = 5;
  static const benchSize = 2;

  final RoundPickStatus status;
  final List<Player> players; // لاعيبة منطقتي المتاحين
  final Map<String, String> sel; // playerId → starting | bench
  final String? captainId;
  final String? viceId; // الكابتن البديل
  final bool saved; // فيه تشكيلة محفوظة للجولة دي
  final bool fromLastRound; // مجهّزة من تشكيلة الجولة اللي فاتت (لسه متحفظتش)

  bool get isLoading => status == RoundPickStatus.loading;
  int get startingCount => sel.values.where((v) => v == 'starting').length;
  int get benchCount => sel.values.where((v) => v == 'bench').length;

  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  RoundPickState copyWith({
    Map<String, String>? sel,
    String? captainId,
    String? viceId,
    bool clearCaptain = false,
    bool clearVice = false,
    bool? saved,
  }) {
    return RoundPickState(
      status: status,
      players: players,
      sel: sel ?? this.sel,
      captainId: clearCaptain ? null : (captainId ?? this.captainId),
      viceId: clearVice ? null : (viceId ?? this.viceId),
      saved: saved ?? this.saved,
      fromLastRound: (saved ?? this.saved) ? false : fromLastRound,
    );
  }

  @override
  List<Object?> get props => [status, players, sel, captainId, viceId, saved, fromLastRound];
}
