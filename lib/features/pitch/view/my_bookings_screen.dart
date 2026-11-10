import 'dart:async';

import '../../../core/widgets/empty_state.dart';
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
import '../widgets/booking_sheets.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'my_bookings_screen_sections.dart';

/// حجوزاتي: كل طلبات الحجز بحالتها (بتتحدّث لوحدها لما صاحب الملعب يرد).
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, required this.userId});
  final String userId;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final BookingsRepository _repo = context.read<BookingsRepository>();
  late Future<List<Booking>> _future = _repo.mine(widget.userId);
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = liveTable('bookings', _reload, eqColumn: 'user_id', eqValue: widget.userId);
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
          Masthead(title: 'حجوزاتي', subtitle: 'MY BOOKINGS', onBack: () => Navigator.pop(context)),
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
                if (snap.data!.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'لسه محجزتش أي ملعب',
                      hint: 'احجز من «احجز ملعب» في الرئيسية',
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [for (final b in snap.data!) _row(b)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
