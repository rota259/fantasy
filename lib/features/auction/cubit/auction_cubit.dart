import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/auction_repository.dart';
import '../data/models/auction.dart';
import '../data/models/auction_bid.dart';

part 'auction_state.dart';

/// ViewModel للمزاد المباشر — بثّ لحظي للمزايدات + عدّاد تنازلي.
class AuctionCubit extends Cubit<AuctionState> {
  AuctionCubit(this._repo) : super(const AuctionState());

  final AuctionRepository _repo;
  StreamSubscription<List<AuctionBid>>? _sub;
  Timer? _tick;

  static const double increment = 0.5; // زيادة المزايدة (مليون)

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const AuctionState(status: AuctionStatus.loaded));
      return;
    }
    emit(const AuctionState(status: AuctionStatus.loading));
    final auction = await _repo.currentAuction();
    if (auction == null) {
      emit(const AuctionState(status: AuctionStatus.loaded));
      return;
    }
    emit(AuctionState(status: AuctionStatus.loaded, auction: auction, secondsLeft: _secs(auction)));

    _sub = _repo.watchBids(auction.id).listen((bids) {
      emit(state.copyWith(bids: bids));
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(state.copyWith(secondsLeft: _secs(state.auction)));
    });
  }

  Future<String> bid(String userId, String bidderName) async {
    final auction = state.auction;
    if (auction == null) return 'مفيش مزاد شغّال';
    try {
      await _repo.placeBid(
        auctionId: auction.id,
        userId: userId,
        bidderName: bidderName,
        amount: state.nextAmount,
      );
      return 'زايدت ${state.nextAmount.toStringAsFixed(1)}م';
    } catch (_) {
      return 'تعذّرت المزايدة';
    }
  }

  int _secs(Auction? a) {
    if (a?.endsAt == null) return 0;
    return a!.endsAt!.difference(DateTime.now()).inSeconds.clamp(0, 5999);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _tick?.cancel();
    return super.close();
  }
}
