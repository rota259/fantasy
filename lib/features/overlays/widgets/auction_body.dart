import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auction/cubit/auction_cubit.dart';

/// جسم المزاد ببيانات حقيقية (بثّ لحظي).
List<Widget> auctionLiveBody(AuctionState s) {
  final a = s.auction!;
  final p = a.player;
  return [
    _currentLot(p?.name ?? '—', p != null ? '${p.team} · ${p.positionAr}' : '', p?.initials ?? '؟', a.basePrice),
    _highest(s.currentAmount, s.highest?.bidderName ?? 'مفيش مزايدات'),
    _bidsHeader(),
    if (s.bids.isEmpty)
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
        child: Text('لسه مفيش مزايدات — زايد الأول!', style: AppText.body(11, color: AppColors.neutral600)),
      ),
    for (final b in s.bids.take(4))
      _bidRow(b.bidderName, '${b.amount.toStringAsFixed(1)}م', accent: b == s.bids.first),
  ];
}

/// جسم المزاد الثابت (وضع demo).
List<Widget> auctionMockBody() {
  return [
    _currentLot('أحمد فتحي', 'التجمع · مهاجم', 'أح', 6.0),
    _highest(8.5, 'محمود'),
    _bidsHeader(),
    _bidRow('محمود', '8.5م', accent: true),
    _bidRow('أنت', '8.0م'),
    _bidRow('كريم', '7.5م'),
    _slots(),
  ];
}

Widget _currentLot(String name, String meta, String ini, double base) {
  return Container(
    color: AppColors.black,
    padding: const EdgeInsets.all(18),
    child: Row(children: [
      Container(
        width: 64, height: 64, alignment: Alignment.center,
        color: AppColors.accent,
        child: Text(ini, style: AppText.h(22, color: AppColors.white)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعروض الآن', style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 2),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppText.h(22, color: AppColors.white, height: 1.05)),
            Text(meta, style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.6))),
          ],
        ),
      ),
      Column(children: [
        Text('الأساس', style: AppText.body(9, color: AppColors.white.withValues(alpha: 0.6))),
        Text('${base.toStringAsFixed(1)}م', style: AppText.h(16, color: AppColors.white)),
      ]),
    ]),
  );
}

Widget _highest(double amount, String bidder) {
  return Container(
    color: AppColors.accent,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    child: Row(children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أعلى مزايدة', style: AppText.kicker(color: AppColors.white.withValues(alpha: 0.85))),
          Text('${amount.toStringAsFixed(1)}م', style: AppText.h(42, color: AppColors.white, height: 0.9)),
        ],
      ),
      const Spacer(),
      Text(bidder, style: AppText.h(13, color: AppColors.white)),
    ]),
  );
}

Widget _bidsHeader() => Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Text('آخر المزايدات', style: AppText.kicker()),
    );

Widget _bidRow(String who, String amount, {bool accent = false}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 18),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
    child: Row(children: [
      Expanded(child: Text(who, style: AppText.h(13))),
      Text(amount, style: AppText.h(14, color: accent ? AppColors.accent : AppColors.ink)),
    ]),
  );
}

Widget _slots() {
  Widget filled(String t) => Container(
      width: 26, height: 26, alignment: Alignment.center,
      color: AppColors.neutral800,
      child: Text(t, style: AppText.h(10, color: AppColors.white)));
  Widget empty() => Container(
      width: 26, height: 26,
      decoration: BoxDecoration(border: Border.all(color: AppColors.neutral400, width: 2)));
  return Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider, width: 2))),
    child: Row(children: [
      Text('فريقك 3/5', style: AppText.body(10, color: AppColors.neutral700, weight: FontWeight.w600)),
      const Spacer(),
      filled('حس'), const SizedBox(width: 6),
      filled('عم'), const SizedBox(width: 6),
      filled('آد'), const SizedBox(width: 6),
      empty(), const SizedBox(width: 6),
      empty(),
    ]),
  );
}
