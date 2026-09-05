part of 'auction_cubit.dart';

enum AuctionStatus { initial, loading, loaded }

class AuctionState extends Equatable {
  const AuctionState({
    this.status = AuctionStatus.initial,
    this.auction,
    this.bids = const [],
    this.secondsLeft = 0,
  });

  final AuctionStatus status;
  final Auction? auction;
  final List<AuctionBid> bids; // الأعلى أولًا
  final int secondsLeft;

  bool get isLoading => status == AuctionStatus.loading;
  AuctionBid? get highest => bids.isEmpty ? null : bids.first;
  double get currentAmount => highest?.amount ?? auction?.basePrice ?? 0;
  double get nextAmount => currentAmount + AuctionCubit.increment;

  /// العدّاد بصيغة mm:ss.
  String get countdown {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  AuctionState copyWith({List<AuctionBid>? bids, int? secondsLeft}) {
    return AuctionState(
      status: status,
      auction: auction,
      bids: bids ?? this.bids,
      secondsLeft: secondsLeft ?? this.secondsLeft,
    );
  }

  @override
  List<Object?> get props => [status, auction, bids, secondsLeft];
}
