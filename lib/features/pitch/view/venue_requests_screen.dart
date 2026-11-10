import 'dart:async';

import '../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/bookings_repository.dart';
import '../data/models/booking.dart';
import '../widgets/booking_sheets.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'venue_requests_screen_sections.dart';

/// طلبات الحجز لصاحب الملعب (ownerId) أو كل الحجوزات للمدير (ownerId = null).
/// بتتحدّث لوحدها أول ما حد يطلب حجز.
class VenueRequestsScreen extends StatefulWidget {
  const VenueRequestsScreen({super.key, this.ownerId});
  final String? ownerId;

  @override
  State<VenueRequestsScreen> createState() => _VenueRequestsScreenState();
}

class _VenueRequestsScreenState extends State<VenueRequestsScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final BookingsRepository _repo = context.read<BookingsRepository>();
  late Future<List<Booking>> _future = _repo.forOwner(widget.ownerId);
  StreamSubscription<void>? _sub;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _sub = liveTable('bookings', _reload);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'طلبات الحجز', subtitle: 'BOOKINGS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<Booking>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final all = snap.data!;
                final pending = all.where((b) => b.isPending && !b.isPast).toList();
                final upcoming = all.where((b) => b.isConfirmed && !b.isPast).toList();
                final old = all.where((b) => !pending.contains(b) && !upcoming.contains(b)).toList();
                if (all.isEmpty) {
                  return Center(
                    child: EmptyState(icon: Icons.inbox_outlined, title: 'لسه مفيش طلبات حجز'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    _header('مستنية ردّك (${pending.length})'),
                    for (final b in pending) _row(b),
                    _header('المؤكدة الجاية (${upcoming.length})'),
                    for (final b in upcoming) _row(b),
                    if (old.isNotEmpty) _header('القديمة'),
                    for (final b in old.take(30)) _row(b),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(t, style: AppText.kicker(color: AppColors.accent)),
  );
}
