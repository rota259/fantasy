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

  Future<void> _open([Venue? v]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VenueFormScreen(userId: widget.userId, editing: v),
      ),
    );
    if (saved != true || !mounted) return;
    _reload();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(v == null ? 'اتضاف ملعبك ✓ — بقى ظاهر لكل الناس' : 'اتعدّل الملعب ✓')));
  }

  Future<void> _delete(Venue v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(),
        title: Text('حذف الملعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «${v.name}»؟ كل حجوزاته وتقييماته هتتمسح.', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.deleteVenue(v.id);
      _reload();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

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
            trailing: GestureDetector(
              onTap: () => _open(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(border: AppBorders.white(0.5)),
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
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final list = snap.data!;
                return ListView(
                  padding: EdgeInsets.zero,
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
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VenueRequestsScreen(ownerId: widget.userId)),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(13),
                          color: AppColors.black,
                          alignment: Alignment.center,
                          child: Text('📅 طلبات الحجز على ملاعبي', style: AppText.h(13, color: AppColors.white)),
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

  Widget _row(Venue v) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => _open(v),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: v.photos.isEmpty
                ? Container(color: AppColors.neutral200, child: const Icon(Icons.stadium_outlined))
                : NetImage(v.photos.first, fallback: Container(color: AppColors.neutral200)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.name, style: AppText.h(14)),
                Text(
                  '${v.price}ج/ساعة · ${formatHour(v.openHour)} لـ ${formatHour(v.closeHour)}',
                  style: AppText.body(10, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _delete(v),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
            ),
          ),
        ],
      ),
    ),
  );
}
