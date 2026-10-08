import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../pitch/data/models/booking.dart';
import '../../pitch/data/models/venue.dart';
import '../../pitch/data/venues_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../pitch/view/venue_form_screen.dart';
import '../../../core/widgets/net_image.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// (مدير) كل الملاعب (بتاعة المدير واليوزرز): إضافة/تعديل/حذف + تغيير صاحب الملعب.
class ManagerVenuesScreen extends StatefulWidget {
  const ManagerVenuesScreen({super.key});

  @override
  State<ManagerVenuesScreen> createState() => _ManagerVenuesScreenState();
}

class _ManagerVenuesScreenState extends State<ManagerVenuesScreen> {
  late final VenuesRepository _repo = context.read<VenuesRepository>();
  late Future<List<Venue>> _future = _repo.fetchAll();

  void _reload() => setState(() {
    _future = _repo.fetchAll();
  });

  Future<void> _open([Venue? v]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VenueFormScreen(userId: context.read<AuthCubit>().state.user?.id ?? '', editing: v, isManager: true),
      ),
    );
    if (saved == true) {
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(v == null ? 'اتضاف الملعب ✓' : 'اتعدّل الملعب ✓')));
      }
    }
  }

  Future<void> _delete(Venue v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف الملعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «${v.name}»؟ كل حجوزاته هتتمسح.', style: AppText.body(13)),
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
      messenger.showSnackBar(SnackBar(content: Text('فشل الحذف: $e')));
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
            title: 'الملاعب',
            subtitle: 'ADMIN · VENUES',
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
                if (snap.data!.isEmpty) {
                  return Center(
                    child: Text('لسه مفيش ملاعب — اضغط "+ ملعب"', style: AppText.body(13, color: AppColors.neutral600)),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [for (final v in snap.data!) _row(v)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Venue v) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => _open(v),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
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
                  Text(
                    [
                      if (!v.hasAnyLocation) '⚠️ من غير موقع' else if (!v.hasLocation) 'لينك بس (مش ظاهر على الخريطة)',
                      v.ownerId == null ? 'الإدارة بيأكّد الحجز' : 'ليه صاحب',
                    ].join(' · '),
                    style: AppText.body(10, color: v.hasAnyLocation ? AppColors.neutral600 : AppColors.danger),
                  ),
                ],
              ),
            ),
            Pressable(
              onTap: () => _delete(v),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
