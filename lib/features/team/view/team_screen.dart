import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../pick/view/match_pick_screen.dart';

/// تبويب فريقي — لكل ماتش قادم تختار تشكيلتك. بيتحدّث لوحده لما المدير يضيف/يعدّل ماتش.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<List<GameMatch>> _future = context.read<MatchesRepository>().fetchUpcoming();
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = liveTable('matches', () {
      if (mounted) {
        setState(() {
          _future = context.read<MatchesRepository>().fetchUpcoming();
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return Column(
      children: [
        const StatusArea(),
        const Masthead(title: 'فريقي · التشكيلات', subtitle: 'PICK TEAM'),
        Expanded(
          child: userId == null
              ? _hint('سجّل دخولك عشان تختار تشكيلتك')
              : FutureBuilder<List<GameMatch>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    }
                    final matches = snap.data!;
                    if (matches.isEmpty) return _hint('مفيش ماتشات قادمة دلوقتي');
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: [for (final m in matches) _row(context, m, userId)],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _hint(String text) => Center(
    child: Text(text, style: AppText.body(13, color: AppColors.neutral600)),
  );

  Widget _row(BuildContext context, GameMatch m, String userId) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchPickScreen(match: m, userId: userId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m.teamA} ضد ${m.teamB}', style: AppText.h(15)),
                  Text(
                    'GW${m.week} · ${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}',
                    style: AppText.body(10, color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            Text(
              m.isLocked ? 'اتقفلت' : 'اختر ›',
              style: AppText.h(12, color: m.isLocked ? AppColors.neutral500 : AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
