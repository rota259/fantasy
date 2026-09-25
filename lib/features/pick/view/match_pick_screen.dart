import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../chips/cubit/chips_cubit.dart';
import '../../chips/data/chip_type.dart';
import '../../chips/data/chips_repository.dart';
import '../../chips/widgets/chips_bar.dart';
import '../../manager/data/lineup_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../players/data/players_repository.dart';
import '../cubit/match_pick_cubit.dart';
import '../data/picks_repository.dart';
import '../widgets/pick_pitch.dart';
import '../widgets/pick_sheets.dart';

/// اختيار التشكيلة لماتش + الكروت الخاصة.
class MatchPickScreen extends StatelessWidget {
  const MatchPickScreen({super.key, required this.match, required this.userId});

  final GameMatch match;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (c) => MatchPickCubit(
            c.read<PlayersRepository>(),
            c.read<PicksRepository>(),
            c.read<LineupRepository>(),
            match,
            userId,
          )..load(),
        ),
        BlocProvider(create: (c) => ChipsCubit(c.read<ChipsRepository>(), match.id)..load()),
      ],
      child: _View(match: match),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.match});
  final GameMatch match;

  /// التعديل مسموح قبل القفل، أو بالوايلد كارد لحد ما الماتش يبدأ.
  bool _editable(ChipType? chip) => !match.hasStarted && (!match.isLocked || chip == ChipType.wildcard);

  Future<void> _save(BuildContext context, bool wildcard) async {
    final messenger = ScaffoldMessenger.of(context);
    final chips = context.read<ChipsCubit>();
    final err = await context.read<MatchPickCubit>().save(wildcard: wildcard);
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتحفظت تشكيلتك ✓ — تقدر تفعّل كارت دلوقتي لو عايز'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
        duration: Duration(milliseconds: err == null ? 2200 : 4000),
      ),
    );
    if (err == null) chips.load(); // الكروت بتحتاج تشكيلة محفوظة
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<ChipsCubit, ChipsState>(
        buildWhen: (p, c) => p.active != c.active,
        builder: (context, chips) {
          final editable = _editable(chips.active);
          return Column(
            children: [
              const StatusArea(),
              Masthead(
                title: '${match.teamA} ضد ${match.teamB}',
                subtitle: 'اختر تشكيلتك · PICK',
                onBack: () => Navigator.pop(context),
              ),
              _deadlineBar(chips.active),
              Expanded(child: _body(context, editable)),
              if (editable) _saveBar(context, chips.active == ChipType.wildcard),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, bool editable) {
    return BlocBuilder<MatchPickCubit, MatchPickState>(
      builder: (context, s) {
        if (s.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (s.players.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                'المدير لسه منزّلش تشكيلة الماتش',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.neutral600),
              ),
            ),
          );
        }
        final cubit = context.read<MatchPickCubit>();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _counts(s),
            PickPitch(
              state: s,
              teamA: match.teamA,
              teamB: match.teamB,
              onSlotTap: editable
                  ? (kind) => showAddPlayerSheet(context, cubit, s, kind, match.teamA, match.teamB)
                  : (_) {},
              onPlayerTap: editable ? (p) => showPlayerOptionsSheet(context, cubit, s, p) : (_) {},
            ),
            const ChipsBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Text(
                'القواعد: ٢ من كل فريق + حارس (أي فريق) + ٢ احتياطي + كابتن.\n'
                'دوس على أي لاعب عشان تعمله كابتن/نائب أو تبدّله. الكارت بيتفعّل بعد ما تحفظ.',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _deadlineBar(ChipType? chip) {
    final String text;
    Color color = AppColors.accent400;
    if (match.hasStarted) {
      text = 'الماتش بدأ — التشكيلة اتقفلت';
      color = AppColors.neutral400;
    } else if (match.isLocked && chip == ChipType.wildcard) {
      text = '🃏 الوايلد كارد شغّال — عدّل لحد ${arabicTime(match.dateTime)}';
    } else if (match.isLocked) {
      text = 'التشكيلة اتقفلت';
      color = AppColors.neutral400;
    } else {
      text = 'يقفل ${arabicWeekday(match.deadline)} ${arabicTime(match.deadline)}';
    }
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      child: Text(text, style: AppText.h(11, color: color)),
    );
  }

  Widget _counts(MatchPickState s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Text('أساسي ${s.startingCount}/5', style: AppText.h(13, color: AppColors.accent)),
          const SizedBox(width: 16),
          Text('احتياطي ${s.benchCount}/2', style: AppText.h(13)),
        ],
      ),
    );
  }

  Widget _saveBar(BuildContext context, bool wildcard) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(12),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => _save(context, wildcard),
          child: Container(
            color: AppColors.accent,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            child: Text('احفظ التشكيلة', style: AppText.h(14, color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}
