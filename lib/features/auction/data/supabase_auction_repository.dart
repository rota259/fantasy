import '../../../core/supabase/supabase_service.dart';
import 'auction_repository.dart';
import 'models/auction.dart';
import 'models/auction_bid.dart';

/// تنفيذ AuctionRepository فوق auctions + auction_bids (Supabase Realtime).
class SupabaseAuctionRepository implements AuctionRepository {
  @override
  Future<Auction?> currentAuction() async {
    final row = await SupabaseService.table('auctions')
        .select('*, players(*)')
        .eq('status', 'live')
        .limit(1)
        .maybeSingle();
    return row == null ? null : Auction.fromMap(row);
  }

  @override
  Stream<List<AuctionBid>> watchBids(String auctionId) {
    return SupabaseService.table('auction_bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('amount', ascending: false)
        .map((rows) => rows.map(AuctionBid.fromMap).toList());
  }

  @override
  Future<void> placeBid({
    required String auctionId,
    required String userId,
    required String bidderName,
    required double amount,
  }) async {
    await SupabaseService.table('auction_bids').insert({
      'auction_id': auctionId,
      'user_id': userId,
      'bidder_name': bidderName,
      'amount': amount,
    });
  }
}
