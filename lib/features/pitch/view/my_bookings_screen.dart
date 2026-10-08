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
import '../widgets/booking_sheets.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// حجوزاتي: كل طلبات الحجز بحالتها (بتتحدّث لوحدها لما صاحب الملعب يرد).
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, required this.userId});
  final String userId;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
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

  void _reload() {
    if (mounted) {
      setState(() {
        _future = _repo.mine(widget.userId);
      });
    }
  }

  Future<void> _cancel(Booking b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('إلغاء الحجز', style: AppText.h(16)),
        content: Text('تلغي حجز ${b.venueName ?? ''} يوم ${slotText(b.day, b.hour)}؟', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لأ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ألغي', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setStatus(b.id, 'cancelled');
      _reload();
      messenger.showSnackBar(const SnackBar(content: Text('اتلغى الحجز')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر الإلغاء: $e')));
    }
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
                    child: Text('لسه محجزتش أي ملعب', style: AppText.body(13, color: AppColors.neutral600)),
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

  Widget _row(Booking b) {
    final canCancel = b.isActive && !b.isPast;
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.venueName ?? 'ملعب', style: AppText.h(14)),
                Text(slotText(b.day, b.hour), style: AppText.body(12, color: AppColors.neutral700)),
                Text(b.statusLabel, style: AppText.h(12, color: _color(b.status))),
              ],
            ),
          ),
          if (canCancel)
            Pressable(
              onTap: () => _cancel(b),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.danger, width: 2),
                ),
                child: Text('إلغاء', style: AppText.h(11, color: AppColors.danger)),
              ),
            ),
        ],
      ),
    );
  }

  Color _color(String s) => switch (s) {
    'confirmed' => AppColors.accent,
    'pending' => const Color(0xFFCA8A04),
    'rejected' => AppColors.danger,
    _ => AppColors.neutral600,
  };
}
