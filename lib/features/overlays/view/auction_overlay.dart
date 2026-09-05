import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auction/cubit/auction_cubit.dart';
import '../../auction/data/auction_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../shell/cubit/app_nav_cubit.dart';
import '../../squad/cubit/squad_cubit.dart';
import '../widgets/auction_body.dart';
import '../widgets/overlay_shell.dart';

class AuctionOverlay extends StatelessWidget {
  const AuctionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) => AuctionCubit(c.read<AuctionRepository>())..load(),
      child: const _AuctionView(),
    );
  }
}

class _AuctionView extends StatelessWidget {
  const _AuctionView();

  @override
  Widget build(BuildContext context) {
    final nav = context.read<AppNavCubit>();
    return BlocBuilder<AuctionCubit, AuctionState>(
      builder: (context, s) {
        final live = SupabaseConfig.isConfigured && s.auction != null;
        return OverlayShell(
          title: 'مزاد مباشر',
          subtitle: 'LIVE AUCTION · شلة الجمعة',
          onBack: nav.back,
          trailing: Container(
            color: AppColors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(live ? s.countdown : '00:08', style: AppText.h(18, color: AppColors.white)),
          ),
          bottomBar: _bar(context, s, live),
          children: s.isLoading
              ? [const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.accent)))]
              : (live ? auctionLiveBody(s) : auctionMockBody()),
        );
      },
    );
  }

  Widget _bar(BuildContext context, AuctionState s, bool live) {
    final nav = context.read<AppNavCubit>();
    final remaining = context.read<SquadCubit>().state.remaining;
    final bidLabel = live ? 'زايد ${s.nextAmount.toStringAsFixed(1)}م' : 'زايد 9.0م';
    return OverlayActionBar(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('رصيدك المتبقّي',
              style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.7), weight: FontWeight.w600)),
          Text(live ? '${remaining.toStringAsFixed(1)}م' : '42.5م', style: AppText.h(16, color: AppColors.white)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _bid(context, live),
              child: Container(
                color: AppColors.accent,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(bidLabel, style: AppText.h(14, color: AppColors.white)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: nav.back,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(border: Border.all(color: AppColors.white.withValues(alpha: 0.4), width: 2)),
              child: Text('باص', style: AppText.h(14, color: AppColors.white)),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _bid(BuildContext context, bool live) async {
    if (!live) {
      context.read<AppNavCubit>().back();
      return;
    }
    final me = context.read<AuthCubit>().state.user;
    final messenger = ScaffoldMessenger.of(context);
    final msg = await context.read<AuctionCubit>().bid(me?.id ?? '', me?.name ?? 'أنت');
    messenger.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 1200)));
  }
}
