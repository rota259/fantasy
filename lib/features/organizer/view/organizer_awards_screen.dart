import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../polls/data/models/poll.dart';
import '../../polls/data/polls_repository.dart';
import '../widgets/nominate_sheet.dart';

part 'organizer_awards_screen_sections.dart';

/// (مدير منطقة) هدف وتصدّي الجولة: يرشّح الأهداف والتصديات من ماتشاته اللي خلصت (لينك فيديو)،
/// وكل ترشيحات المديرين بتتجمع في تصويت الجولة لمنطقتهم — واليوزرز يصوّتوا.
class OrganizerAwardsScreen extends StatefulWidget {
  const OrganizerAwardsScreen({super.key, required this.organizerId});
  final String organizerId;

  @override
  State<OrganizerAwardsScreen> createState() => _OrganizerAwardsScreenState();
}

class _OrganizerAwardsScreenState extends State<OrganizerAwardsScreen> {
  late final PollsRepository _polls = context.read<PollsRepository>();
  late Future<(List<GameMatch>, List<AwardNomination>)> _future = _load();

  void _reload() => setState(() => _future = _load());

  Future<void> _nominate(GameMatch m) async {
    final added = await showNominateSheet(context, m);
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'هدف وتصدّي الجولة', subtitle: 'رشّح من ماتشاتك', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const SkeletonList();
                if (!snap.hasData) {
                  return Center(child: Text('حصلت مشكلة — جرّب تاني', style: AppText.body(13)));
                }
                final (matches, mine) = snap.data!;
                return ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Text(
                        'اختار ماتش خلص، وحدّد اللاعب ولينك الفيديو. كل ترشيحات مديرين منطقتك بتتجمع في تصويت واحد '
                        'للجولة، وأول ترشيح بيبعت إشعار لأهل المنطقة يصوّتوا.',
                        style: AppText.body(12, color: AppColors.neutral700),
                      ),
                    ),
                    if (mine.isNotEmpty) ...[_header('ترشيحاتي'), for (final n in mine) _nomination(n)],
                    _header('ماتشاتي اللي خلصت'),
                    if (matches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'مفيش ماتشات خلصت في آخر ١٠ أيام',
                          style: AppText.body(13, color: AppColors.neutral600),
                        ),
                      ),
                    for (final (i, m) in matches.indexed) FadeSlideIn(index: i, child: _match(m)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Text(t, style: AppText.kicker(color: AppColors.accent)),
  );
}
