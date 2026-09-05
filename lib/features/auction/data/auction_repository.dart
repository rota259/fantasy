import 'models/auction.dart';
import 'models/auction_bid.dart';

/// عقد المزاد المباشر.
abstract interface class AuctionRepository {
  /// غرفة المزاد الشغّالة حاليًا (مع اللاعب المعروض).
  Future<Auction?> currentAuction();

  /// بثّ لحظي للمزايدات (الأعلى أولًا).
  Stream<List<AuctionBid>> watchBids(String auctionId);

  /// تسجيل مزايدة.
  Future<void> placeBid({
    required String auctionId,
    required String userId,
    required String bidderName,
    required double amount,
  });
}
