import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/bookings_repository.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';
import '../widgets/booking_sheets.dart';
import '../widgets/slot_grid.dart';
import '../widgets/venue_contact_bar.dart';
import '../widgets/venue_gallery.dart';
import '../widgets/venue_reviews_section.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'venue_screen_sections.dart';

/// صفحة الملعب: الصور + البيانات + التواصل + المواعيد المتاحة/المحجوزة + طلب الحجز.
class VenueScreen extends StatefulWidget {
  const VenueScreen({super.key, required this.venue, required this.userId});

  final Venue venue;
  final String userId;

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final BookingsRepository _repo = context.read<BookingsRepository>();
  List<Booking> _bookings = const [];
  bool _loading = true;
  bool _sending = false;
  int _day = 0;
  int? _hour;
  StreamSubscription<void>? _sub;
  Timer? _poll;

  Venue get v => widget.venue;

  @override
  void initState() {
    super.initState();
    _load();
    // حجوزاتي على الملعب بتتحدّث فورًا، وحجوزات الناس (مخفية للخصوصية) كل ٣٠ ثانية
    _sub = liveTable('bookings', _load, eqColumn: 'venue_id', eqValue: v.id);
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: v.name, subtitle: 'احجز ملعبك', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                VenueGallery(photos: v.photos),
                _info(),
                VenueContactBar(venue: v),
                VenueReviewsSection(venue: v, userId: widget.userId),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('المواعيد', style: AppText.h(15)),
                ),
                if (_loading)
                  Padding(padding: EdgeInsets.all(30), child: const SkeletonList())
                else
                  SlotGrid(
                    venue: v,
                    bookings: _bookings,
                    userId: widget.userId,
                    dayIndex: _day,
                    selectedHour: _hour,
                    onDay: (i) => setState(() {
                      _day = i;
                      _hour = null;
                    }),
                    onPick: (h) => setState(() => _hour = h),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            color: AppColors.black,
            padding: const EdgeInsets.all(12),
            child: SafeArea(
              top: false,
              child: Pressable(
                onTap: (_hour == null || _sending) ? null : _book,
                child: Container(
                  decoration: BoxDecoration(
                    color: (_hour == null || _sending) ? AppColors.neutral600 : AppColors.accent,
                    borderRadius: AppRadius.md,
                  ),
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text(
                    _sending
                        ? 'بيتبعت…'
                        : (_hour == null ? 'اختار ميعاد متاح' : 'اجمع فريقك واحجز · ${formatHour(_hour!)}'),
                    style: AppText.h(14, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
