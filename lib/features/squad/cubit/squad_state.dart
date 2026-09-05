part of 'squad_cubit.dart';

enum SquadStatus { initial, loading, loaded, saving }

class SquadState extends Equatable {
  const SquadState({
    this.status = SquadStatus.initial,
    this.players = const [],
    this.captainId,
    this.dirty = false,
  });

  final SquadStatus status;
  final List<Player> players;
  final String? captainId; // كابتن التشكيلة (null = أوتوماتيك: أعلى نقاط)
  final bool dirty; // فيه تغييرات مش محفوظة

  static const double budget = 100.0; // الميزانية بالمليون

  bool get isLoading => status == SquadStatus.loading;
  bool get isSaving => status == SquadStatus.saving;
  bool get hasSquad => players.isNotEmpty;
  int get count => players.length;
  bool get hasGk => players.any((p) => p.position == 'GK');
  double get value => players.fold(0.0, (sum, p) => sum + p.price);
  double get remaining => budget - value;

  @override
  List<Object?> get props => [status, players, captainId, dirty];
}
