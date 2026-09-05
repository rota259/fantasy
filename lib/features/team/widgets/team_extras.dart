import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../squad/cubit/squad_cubit.dart';

/// شريط قيم الفريق (قيمة/رصيد/تحويلات) — حيّ من التشكيلة.
class TeamValueStrip extends StatelessWidget {
  const TeamValueStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: BlocBuilder<SquadCubit, SquadState>(
        builder: (context, s) {
          final live = SupabaseConfig.isConfigured;
          final value = live ? '${s.value.toStringAsFixed(1)}م' : '100.4م';
          final balance = live ? '${s.remaining.toStringAsFixed(1)}م' : '1.6م';
          return Row(
            children: [
              _cell('قيمة الفريق', value, border: true),
              _cell('الرصيد', balance, border: true),
              _cell('تحويلات', '1 مجاني', valueColor: AppColors.accent),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(String k, String v, {bool border = false, Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: border ? const Border(left: BorderSide(color: AppColors.divider)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: AppText.kicker()),
            const SizedBox(height: 2),
            Text(v, style: AppText.h(16, color: valueColor ?? AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

/// دكّة الاحتياطي (كارتين).
class TeamBench extends StatelessWidget {
  const TeamBench({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الاحتياطي · BENCH', style: AppText.kicker()),
          const SizedBox(height: 9),
          Row(
            children: [
              _card('سي', 'سيف', 'وسط · 4.5م'),
              const SizedBox(width: 10),
              _card('مح', 'محمد', 'دفاع · 4.0م'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(String ini, String name, String meta) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider, width: 2)),
        child: Row(
          children: [
            InitialsTile(ini, size: 28, fontSize: 11),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h(12)),
                Text(meta, style: AppText.body(9, color: AppColors.neutral700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// زرّا "اختر الكابتن" و"اقتراح المدرّب".
class TeamActions extends StatelessWidget {
  const TeamActions({super.key, required this.onCoach, required this.onCaptain});

  final VoidCallback onCoach;
  final VoidCallback onCaptain;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _btn('اختر الكابتن', onCaptain),
          const SizedBox(width: 8),
          _btn('اقتراح المدرّب ✨', onCoach),
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
          child: Text(label, style: AppText.h(12)),
        ),
      ),
    );
  }
}
