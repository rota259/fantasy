import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/bookings_repository.dart';
import '../data/models/booking.dart';
import '../widgets/booking_sheets.dart';

/// طلبات الحجز لصاحب الملعب (ownerId) أو كل الحجوزات للمدير (ownerId = null).
/// بتتحدّث لوحدها أول ما حد يطلب حجز.
class VenueRequestsScreen extends StatefulWidget {
  const VenueRequestsScreen({super.key, this.ownerId});
  final String? ownerId;

  @override
  State<VenueRequestsScreen> createState() => _VenueRequestsScreenState();
}

class _VenueRequestsScreenState extends State<VenueRequestsScreen> {
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

  void _reload() {
    if (mounted) {
      setState(() {
        _future = _repo.forOwner(widget.ownerId);
      });
    }
  }

  Future<void> _set(Booking b, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(b.id));
    try {
      await _repo.setStatus(b.id, status);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (status) {
            'confirmed' => 'اتأكد الحجز ✅ واتبعت إشعار للحاجز',
            'rejected' => 'اترفض الطلب واتبعت إشعار للحاجز',
            _ => 'اتلغى الحجز',
          }),
        ),
      );
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر التحديث: $e')));
    } finally {
      if (mounted) setState(() => _busy.remove(b.id));
    }
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
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final all = snap.data!;
                final pending = all.where((b) => b.isPending && !b.isPast).toList();
                final upcoming = all.where((b) => b.isConfirmed && !b.isPast).toList();
                final old = all.where((b) => !pending.contains(b) && !upcoming.contains(b)).toList();
                if (all.isEmpty) {
                  return Center(
                    child: Text('لسه مفيش طلبات حجز', style: AppText.body(13, color: AppColors.neutral600)),
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

  Widget _row(Booking b) {
    final busy = _busy.contains(b.id);
    final phone = b.userPhone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${b.venueName ?? ''} · ${slotText(b.day, b.hour)}', style: AppText.h(14))),
              Text(b.statusLabel, style: AppText.body(11, color: AppColors.neutral700)),
            ],
          ),
          Text(
            '${b.userName ?? 'يوزر'}${phone != null ? ' · $phone' : ''}',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
          if (b.note != null) Text('«${b.note}»', style: AppText.body(12)),
          if (!b.isPast && b.isActive) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (phone != null) _btn('📞', AppColors.black, busy ? null : () => Launchers.call(phone)),
                if (b.isPending) ...[
                  _btn('✅ أكّد', AppColors.accent, busy ? null : () => _set(b, 'confirmed')),
                  _btn('❌ ارفض', AppColors.danger, busy ? null : () => _set(b, 'rejected')),
                ] else
                  _btn('إلغاء الحجز', AppColors.danger, busy ? null : () => _set(b, 'cancelled')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback? onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        color: onTap == null ? AppColors.neutral500 : color,
        padding: const EdgeInsets.all(10),
        alignment: Alignment.center,
        child: Text(label, style: AppText.h(12, color: AppColors.white)),
      ),
    ),
  );
}
