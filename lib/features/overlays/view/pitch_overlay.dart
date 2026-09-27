import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../pitch/cubit/venues_cubit.dart';
import '../../pitch/data/models/venue.dart';
import '../../pitch/data/venues_repository.dart';
import '../../pitch/view/my_bookings_screen.dart';
import '../../pitch/view/venue_screen.dart';
import '../../pitch/widgets/venue_tile.dart';
import '../../pitch/widgets/venues_map_view.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../../core/widgets/motion.dart';

/// احجز ملعبك: الملاعب بتابين (قايمة / خريطة) → صفحة الملعب والحجز.
/// (من غير OverlayShell عشان الخريطة تاخد المساحة كلها من غير scroll فوقها.)
/// [onClose]: لو اتفتحت كصفحة لوحدها (زي عند مدير المنطقة) بدل الـ overlay.
class PitchOverlay extends StatelessWidget {
  const PitchOverlay({super.key, this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => VenuesCubit(c.read<VenuesRepository>())..load(),
      child: _PitchView(onClose: onClose),
    );
  }
}

class _PitchView extends StatefulWidget {
  const _PitchView({this.onClose});
  final VoidCallback? onClose;

  @override
  State<_PitchView> createState() => _PitchViewState();
}

class _PitchViewState extends State<_PitchView> {
  bool _map = false;

  void _open(Venue v) {
    final userId = context.read<AuthCubit>().state.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سجّل دخولك الأول')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueScreen(venue: v, userId: userId),
      ),
    );
  }

  void _myBookings() {
    final userId = context.read<AuthCubit>().state.user?.id;
    if (userId == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => MyBookingsScreen(userId: userId)));
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return Material(
      color: AppColors.bg,
      child: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'احجز ملعبك',
            subtitle: 'BOOK A PITCH',
            onBack: widget.onClose ?? nav.back,
            trailing: Pressable(
              onTap: _myBookings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: AppRadius.md, border: AppBorders.white(0.5)),
                child: Text('حجوزاتي', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ),
          Row(children: [_tab('القايمة', false), _tab('الخريطة', true)]),
          Expanded(
            child: BlocBuilder<VenuesCubit, VenuesState>(
              builder: (context, s) {
                if (s.isLoading) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                if (s.venues.isEmpty) {
                  return Center(
                    child: Text('لسه مفيش ملاعب متاحة', style: AppText.body(13, color: AppColors.neutral600)),
                  );
                }
                if (_map) return VenuesMapView(venues: s.venues, onOpen: _open);
                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    for (final v in s.venues) VenueTile(venue: v, rating: s.ratings[v.id], onTap: () => _open(v)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool map) {
    final active = _map == map;
    return Expanded(
      child: Pressable(
        onTap: () => setState(() => _map = map),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: active ? AppColors.accent : AppColors.divider, width: 3)),
          ),
          child: Text(label, style: AppText.h(13, color: active ? AppColors.accent : AppColors.neutral600)),
        ),
      ),
    );
  }
}
