import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/share/share_card.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/prow_row.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../badges/data/badges_repository.dart';
import '../cubit/leagues_cubit.dart';
import '../data/leagues_repository.dart';
import '../data/models/league_standing.dart';
import '../widgets/league_dialogs.dart';
import '../widgets/leagues_widgets.dart';

/// تبويب الدوريات: اعمل دوري أو انضم بكود، وشوف الترتيب بالصور والشارات.
class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthCubit>().state.user?.id;
    return BlocProvider(
      create: (c) => LeaguesCubit(c.read<LeaguesRepository>(), c.read<BadgesRepository>())..load(userId),
      child: _LeaguesView(userId: userId),
    );
  }
}

class _LeaguesView extends StatelessWidget {
  const _LeaguesView({this.userId});
  final String? userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StatusArea(),
        Masthead(
          title: 'الدوريات',
          subtitle: 'LEAGUES',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _headerBtn('+ دوري', () => _create(context)),
              const SizedBox(width: 6),
              _headerBtn('انضم', () => _join(context)),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<LeaguesCubit, LeaguesState>(
            builder: (context, s) {
              if (s.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  LeaguesHero(rank: s.globalRank > 0 ? '${s.globalRank}' : '—'),
                  ..._body(context, s),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _headerBtn(String t, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(border: AppBorders.white(0.5)),
      child: Text(t, style: AppText.h(12, color: AppColors.white)),
    ),
  );

  List<Widget> _body(BuildContext context, LeaguesState s) {
    final sel = s.selected;
    if (sel == null) {
      return [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            'لسه مش في أي دوري — اعمل دوري لصحابك أو انضم بكود',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.neutral600),
          ),
        ),
      ];
    }
    final cubit = context.read<LeaguesCubit>();
    final l = sel.league;
    return [
      for (final ml in s.myLeagues)
        ProwRow(
          onTap: () => cubit.selectLeague(ml.league.id),
          leading: InitialsTile(
            ml.league.name.isNotEmpty ? ml.league.name.substring(0, 1) : '?',
            background: ml.league.id == l.id ? AppColors.accent : AppColors.neutral200,
            color: ml.league.id == l.id ? AppColors.white : AppColors.neutral800,
          ),
          title: ml.league.name,
          subtitle: Text(
            '${ml.league.memberCount} عضو · ${ml.league.typeLabel}${ml.league.ownerId == userId ? ' · بتاعك' : ''}',
            style: AppText.body(10, color: AppColors.neutral700),
          ),
          trailing: Text('#${ml.userRank}', style: AppText.h(16)),
        ),
      LeagueCodeBar(
        league: l,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: l.inviteCode));
          ShareCard.text('انضم لدوري «${l.name}» في الخماسي ⚽ — الكود: ${l.inviteCode}');
        },
        onLeave: () => _leave(context, sel.league.ownerId == userId, l.name, () => cubit.leaveOrDelete(l)),
        isOwner: l.ownerId == userId,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: Column(
          children: [
            for (final LeagueStanding st in s.standings)
              StandingRow(standing: st, me: st.userId == userId, badges: s.badges[st.userId] ?? const []),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Text(
          'لو اتنين متعادلين في النقط: اللي اختار لاعيبة امتلاكها أقل (تحت ٢٥٪) أكتر بيبقى فوق 🧭',
          style: AppText.body(10, color: AppColors.neutral600),
        ),
      ),
    ];
  }

  Future<void> _join(BuildContext context) async {
    final cubit = context.read<LeaguesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final code = await askInviteCode(context);
    if (code == null || code.isEmpty) return;
    messenger.showSnackBar(SnackBar(content: Text(await cubit.join(code))));
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<LeaguesCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final input = await askNewLeague(context);
    if (input == null) return;
    try {
      final l = await cubit.create(input.name, input.type);
      messenger.showSnackBar(SnackBar(content: Text('اتعمل الدوري ✓ — الكود ${l.inviteCode}، ابعته لصحابك')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'تعذّر إنشاء الدوري'))));
    }
  }

  Future<void> _leave(BuildContext context, bool owner, String name, Future<String> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(),
        title: Text(owner ? 'حذف الدوري' : 'الخروج من الدوري', style: AppText.h(16)),
        content: Text(owner ? 'الدوري «$name» هيتمسح لكل الأعضاء.' : 'هتخرج من «$name».', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(owner ? 'احذف' : 'اخرج', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) messenger.showSnackBar(SnackBar(content: Text(await action())));
  }
}
