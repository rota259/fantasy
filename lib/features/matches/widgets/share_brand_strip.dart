import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/widgets/net_image.dart';
import '../../pitch/data/models/venue.dart';
import '../../pitch/data/venues_repository.dart';
import '../../tournaments/data/models/tournament.dart';
import '../../tournaments/data/tournaments_repository.dart';
import '../data/models/game_match.dart';

/// تحت كارت الشير: لوجو الملعب واسمه + راعي البطولة — الدعاية اللي بنبيعها لصاحب الملعب والراعي.
class ShareBrandStrip extends StatefulWidget {
  const ShareBrandStrip({super.key, required this.match});
  final GameMatch match;

  @override
  State<ShareBrandStrip> createState() => _ShareBrandStripState();
}

class _ShareBrandStripState extends State<ShareBrandStrip> {
  late final Future<(Venue?, Tournament?)> _future = _load();

  Future<(Venue?, Tournament?)> _load() async {
    final m = widget.match, vid = m.place?.venueId, tid = m.tournamentId;
    final venues = context.read<VenuesRepository>(), tournaments = context.read<TournamentsRepository>();
    final v = vid == null ? null : await venues.fetchById(vid).catchError((_) => null);
    final t = tid == null ? null : await tournaments.byId(tid).catchError((_) => null);
    return (v, t);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<(Venue?, Tournament?)>(
    future: _future,
    builder: (context, snap) {
      final (v, t) = snap.data ?? (null, null);
      final name = v?.name ?? widget.match.place?.name;
      final sponsor = t?.sponsor;
      if (name == null && sponsor == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (v?.logoUrl != null)
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(left: 8),
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                child: NetImage(v!.logoUrl!, fallback: const SizedBox.shrink()),
              ),
            Flexible(
              child: Text(
                [if (name != null) '🏟️ $name', if (sponsor != null) 'برعاية $sponsor'].join('  ·  '),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppText.h(13, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    },
  );
}
