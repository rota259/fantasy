import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/net_image.dart';
import '../data/models/tournament.dart';
import '../data/tournaments_repository.dart';

part 'tournament_fantasy_tab_sections.dart';
part 'tournament_fantasy_tab_sections2.dart';

/// فانتازي البطولة: تشكيلة لوحدها لكل بطولة — ٥ لاعيبة من فرقها (حارس + ٤ · ٢ بحد أقصى من الفريق) وكابتن ×٢.
/// تتغيّر بين الماتشات (مقفولة وماتش شغال)، ولها ترتيب لوحدها.
class TournamentFantasyTab extends StatefulWidget {
  const TournamentFantasyTab({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  State<TournamentFantasyTab> createState() => _TournamentFantasyTabState();
}

class _TournamentFantasyTabState extends State<TournamentFantasyTab> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final TournamentsRepository _repo = context.read<TournamentsRepository>();
  TournamentFantasy? _data;
  final _sel = <String>[];
  String? _captain;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) {
      return _failed
          ? Center(
              child: TextButton(onPressed: _load, child: const Text('حصلت مشكلة — جرّب تاني')),
            )
          : const SkeletonList();
    }
    final byTeam = <String, List<FantasyPlayer>>{};
    for (final p in d.players) {
      byTeam.putIfAbsent(p.team, () => []).add(p);
    }
    final changed = !(_sel.length == d.mine.length && _sel.every(d.mine.contains) && _captain == d.captain);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _summary(d),
          _lineup(d),
          if (d.open && changed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'بيتحفظ…' : 'احفظ تشكيلتي')),
            ),
          if (d.canPlay && !d.finished) ...[
            for (final e in byTeam.entries) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
                child: Text(e.key, style: AppText.h(13, color: AppColors.accent700)),
              ),
              for (final p in e.value) _playerRow(p, d.open),
            ],
            if (d.players.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'لسه مفيش لاعيبة في فرق البطولة — المنظّم بيضيفهم',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.neutral600),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text('ترتيب فانتازي البطولة', style: AppText.kicker(color: AppColors.accent)),
          ),
          if (d.standings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('لسه محدش عمل تشكيلة', style: AppText.body(13, color: AppColors.neutral600)),
            ),
          for (final (i, r) in d.standings.indexed)
            FadeSlideIn(
              index: i,
              child: Container(
                margin: AppDecor.tileMargin,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: r.mine
                    ? AppDecor.tile.copyWith(border: Border.all(color: AppColors.accent, width: 1.4))
                    : AppDecor.tile,
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r.rank}', style: AppText.h(13, color: AppColors.accent)),
                    ),
                    Expanded(child: Text(r.name, style: AppText.h(13))),
                    Text('${r.points}', style: AppText.h(17)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
