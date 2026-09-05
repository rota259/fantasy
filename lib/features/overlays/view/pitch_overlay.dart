import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pill.dart';
import '../../pitch/cubit/venues_cubit.dart';
import '../../pitch/data/models/venue.dart';
import '../../pitch/data/venues_repository.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../widgets/overlay_shell.dart';
import '../widgets/venue_card.dart';

class PitchOverlay extends StatelessWidget {
  const PitchOverlay({super.key});

  static const _days = ['الخميس', 'الجمعة', 'السبت', 'الأحد'];

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocProvider(
      create: (c) => VenuesCubit(c.read<VenuesRepository>())..load(),
      child: OverlayShell(
        title: 'احجز ملعبك',
        subtitle: 'BOOK A PITCH · القاهرة',
        onBack: nav.back,
        trailing: const Icon(Icons.location_on_outlined, color: AppColors.white, size: 22),
        bottomBar: OverlayActionBar(
          child: GestureDetector(
            onTap: nav.back,
            child: Container(
              color: AppColors.accent,
              padding: const EdgeInsets.all(11),
              alignment: Alignment.center,
              child: Text('اجمع فريقك واحجز', style: AppText.h(14, color: AppColors.white)),
            ),
          ),
        ),
        children: [
          _mapStrip(),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) =>
                  i == 0 ? Pill.accent(_days[i]) : Pill(_days[i], border: AppColors.divider),
            ),
          ),
          BlocBuilder<VenuesCubit, VenuesState>(
            builder: (context, s) {
              if (s.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                );
              }
              return SupabaseConfig.isConfigured ? _live(s.venues) : _mock();
            },
          ),
        ],
      ),
    );
  }

  Widget _live(List<Venue> venues) {
    if (venues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30),
        child: Center(child: Text('مفيش ملاعب قريبة', style: AppText.body(13, color: AppColors.neutral600))),
      );
    }
    return Column(children: [
      for (var i = 0; i < venues.length; i++) _card(venues[i], first: i == 0),
    ]);
  }

  Widget _card(Venue v, {required bool first}) {
    return VenueCard(
      name: v.name,
      price: '${v.price}ج',
      meta: '${v.distanceKm.toStringAsFixed(1)} كم · ${v.surface}${v.feature != null ? ' · ${v.feature}' : ''}',
      fillLabel: v.isFull ? '${v.capacity}/${v.capacity} مكتمل' : '${v.filled}/${v.capacity} لاعبين',
      fill: v.fill,
      action: v.isFull ? 'قائمة انتظار' : '${v.slotTime} احجز',
      full: v.isFull,
      topBorder: !first,
    );
  }

  Widget _mock() {
    return const Column(children: [
      VenueCard(name: 'ملعب التجمع الخماسي', price: '120ج', meta: '1.2 كم · نجيلة صناعية · إضاءة', fillLabel: '6/10 لاعبين', fill: 0.6, action: '9:00م احجز', topBorder: false),
      VenueCard(name: 'أرينا المعادي', price: '150ج', meta: '3.4 كم · نجيلة صناعية · مغطّى', fillLabel: '10/10 مكتمل', fill: 1.0, action: 'قائمة انتظار', full: true),
      VenueCard(name: 'ستاد أكتوبر 6', price: '100ج', meta: '5.1 كم · نجيلة صناعية', fillLabel: '2/10 لاعبين', fill: 0.2, action: '10:30م احجز'),
    ]);
  }

  Widget _mapStrip() {
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: AppColors.night2,
        border: Border(bottom: BorderSide(color: AppColors.black, width: 2)),
      ),
      child: Stack(children: [
        const Align(alignment: Alignment(-0.4, -0.2), child: _Dot(AppColors.accent)),
        const Align(alignment: Alignment(0.24, 0.24), child: _Dot(AppColors.white)),
        const Align(alignment: Alignment(-0.04, -0.4), child: _Dot(AppColors.white)),
        Positioned(
          right: 12,
          bottom: 8,
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Text('3 ملاعب قريبة', style: AppText.h(10, color: AppColors.black)),
          ),
        ),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: 14, height: 14, color: color);
}
