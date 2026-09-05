import 'package:equatable/equatable.dart';

/// مزايدة في المزاد (جدول auction_bids).
class AuctionBid extends Equatable {
  const AuctionBid({
    required this.id,
    required this.userId,
    required this.bidderName,
    required this.amount,
  });

  final String id;
  final String userId;
  final String bidderName;
  final double amount;

  factory AuctionBid.fromMap(Map<String, dynamic> map) => AuctionBid(
        id: map['id'].toString(),
        userId: map['user_id'].toString(),
        bidderName: (map['bidder_name'] ?? '') as String,
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [id, userId, bidderName, amount];
}
