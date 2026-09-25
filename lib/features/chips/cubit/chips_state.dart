part of 'chips_cubit.dart';

class ChipsState extends Equatable {
  const ChipsState({this.loaded = false, this.chips = const [], this.busy = false});

  final bool loaded;
  final List<ChipStatus> chips;
  final bool busy;

  /// الكارت المفعّل في الماتش ده (لو فيه).
  ChipType? get active {
    for (final c in chips) {
      if (c.active) return c.type;
    }
    return null;
  }

  ChipsState copyWith({bool? busy}) => ChipsState(loaded: loaded, chips: chips, busy: busy ?? this.busy);

  @override
  List<Object?> get props => [loaded, chips, busy];
}
