import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_pitch.dart';
import '../../../core/widgets/player_token.dart';
import '../../squad/cubit/squad_cubit.dart';
import '../../squad/widgets/squad_tokens.dart';

/// قسم "فريقي" في الهوم: عنوان + زر تعديل + أرض خماسية بالتوكنات.
class HomeSquad extends StatelessWidget {
  const HomeSquad({super.key, required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('فريقي · خماسي', style: AppText.h(15)),
              GestureDetector(
                onTap: onEdit,
                child: Text('عدّل ›', style: AppText.h(12, color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<SquadCubit, SquadState>(
            builder: (context, s) => PentagonPitch(
              height: 250,
              border: AppBorders.solid,
              tokens: SupabaseConfig.isConfigured
                  ? squadTokens(s.players, showPoints: true, captainId: s.captainId)
                  : _mock,
            ),
          ),
        ],
      ),
    );
  }

  static const _mock = [
    PitchToken(leftPct: 71, topPct: 20, child: PlayerToken(number: '8', name: 'عمر', chip: '24', isCaptain: true, chipAccent: true)),
    PitchToken(leftPct: 29, topPct: 20, child: PlayerToken(number: '9', name: 'آدم', chip: '14')),
    PitchToken(leftPct: 84, topPct: 60, child: PlayerToken(number: '2', name: 'زياد', chip: '2')),
    PitchToken(leftPct: 16, topPct: 60, child: PlayerToken(number: '5', name: 'كريم', chip: '8')),
    PitchToken(leftPct: 50, topPct: 86, child: PlayerToken(number: 'GK', name: 'حسام', chip: '6')),
  ];
}
