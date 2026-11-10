import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
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

part 'manager_venues_screen_sections.dart';

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
                    child: EmptyState(icon: Icons.stadium_outlined, title: 'لسه مفيش ملاعب', hint: 'اضغط «+ ملعب» فوق'),
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
}
