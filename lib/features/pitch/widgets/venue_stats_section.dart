import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_avatar.dart';
import '../data/models/venue_extras.dart';
import '../data/venues_repository.dart';

part 'venue_stats_section_parts.dart';

/// إحصائيات الملعب: أسطورة الملعب + الهدافين + الأرقام — ولصاحب الملعب: أكتر الساعات زحمة.
class VenueStatsSection extends StatefulWidget {
  const VenueStatsSection({super.key, required this.venueId, required this.isOwner});

  final String venueId;
  final bool isOwner;

  @override
  State<VenueStatsSection> createState() => _VenueStatsSectionState();
}

class _VenueStatsSectionState extends State<VenueStatsSection> {
  late final Future<VenueStats> _future = context.read<VenuesRepository>().stats(widget.venueId);

  @override
  Widget build(BuildContext context) => FutureBuilder<VenueStats>(
    future: _future,
    builder: (context, snap) {
      final s = snap.data;
      if (s == null || (s.matches == 0 && s.upcoming == 0 && !widget.isOwner)) return const SizedBox.shrink();
      final legend = s.legend;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الملعب بالأرقام', style: AppText.h(15)),
            const SizedBox(height: 8),
            Row(
              children: [
                _num('${s.matches}', 'ماتش اتلعب'),
                _num('${s.teams}', 'فريق'),
                _num('${s.goals}', 'جول'),
                _num('${s.tournaments}', 'بطولة'),
              ],
            ),
            if (legend != null) ...[const SizedBox(height: 10), _legend(legend)],
            if (s.top.length > 1) ...[
              const SizedBox(height: 10),
              Text('هدافين الملعب', style: AppText.h(13)),
              for (final (i, p) in s.top.skip(1).indexed) _scorer(i + 2, p),
            ],
            if (widget.isOwner) ...[const SizedBox(height: 14), _hours(s.hours)],
          ],
        ),
      );
    },
  );
}
