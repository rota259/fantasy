import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';
import '../data/venues_repository.dart';
import 'venue_form_screen.dart';
import 'venue_requests_screen.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'my_venues_screen_sections.dart';

/// ملاعبي: أي يوزر يضيف ملعبه (لحد ٥)، يعدّله، ويوافق على طلبات الحجز.
class MyVenuesScreen extends StatefulWidget {
  const MyVenuesScreen({super.key, required this.userId});
  final String userId;

  @override
  State<MyVenuesScreen> createState() => _MyVenuesScreenState();
}

class _MyVenuesScreenState extends State<MyVenuesScreen> {
  late final VenuesRepository _repo = context.read<VenuesRepository>();
  late Future<List<Venue>> _future = _repo.fetchOwned(widget.userId);

  void _reload() => setState(() {
    _future = _repo.fetchOwned(widget.userId);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'ملاعبي',
            subtitle: 'MY PITCHES',
            onBack: () => Navigator.pop(context),
            trailing: Pressable(
              onTap: () => _open(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: AppRadius.md, border: AppBorders.white(0.5)),
                child: Text('+ ملعب', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Venue>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final list = snap.data!;
                return ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(30),
                        child: Text(
                          'عندك ملعب؟ دوس "+ ملعب" وضيفه — الناس هتحجز منك وانت توافق.',
                          textAlign: TextAlign.center,
                          style: AppText.body(13, color: AppColors.neutral600),
                        ),
                      )
                    else ...[
                      Pressable(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VenueRequestsScreen(ownerId: widget.userId)),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                          alignment: Alignment.center,
                          child: Text('طلبات الحجز على ملاعبي', style: AppText.h(13, color: AppColors.white)),
                        ),
                      ),
                      for (final v in list) _row(v),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
