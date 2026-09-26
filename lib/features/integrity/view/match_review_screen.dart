import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../events/data/events_repository.dart';
import '../../events/data/models/match_event.dart';
import '../../matches/data/models/game_match.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../data/integrity_repository.dart';
import '../widgets/match_sheet_view.dart';
import '../widgets/note_dialog.dart';

typedef MatchSheet = ({List<MatchEvent> events, Map<String, Player> players});

/// تحمّل ورقة الماتش (الأحداث + لاعيبة الفريقين).
Future<MatchSheet> loadMatchSheet(BuildContext context, GameMatch m) async {
  final (events, players) = await (
    context.read<EventsRepository>().fetchByMatch(m.id),
    context.read<PlayersRepository>().fetchByTeams(m.teams),
  ).wait;
  return (events: events, players: {for (final p in players) p.id: p});
}

/// اللاعب الموثّق يأكد ورقة الماتش ✅ أو يعترض ❌ (بيرجّع true لو بعت رأيه).
class MatchReviewScreen extends StatefulWidget {
  const MatchReviewScreen({super.key, required this.match});
  final GameMatch match;

  @override
  State<MatchReviewScreen> createState() => _MatchReviewScreenState();
}

class _MatchReviewScreenState extends State<MatchReviewScreen> {
  late final Future<MatchSheet> _sheet = loadMatchSheet(context, widget.match);
  bool _busy = false;

  Future<void> _send(bool ok) async {
    String? note;
    if (!ok) {
      note = await showNoteDialog(context, title: 'إيه الغلط؟', hint: 'مثلًا: الجول التاني جابه فلان مش علان');
      if (note == null) return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final r = await context.read<IntegrityRepository>().reviewMatch(widget.match.id, ok: ok, note: note);
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (r) {
            'approved' => 'الفريقين أكّدوا — الماتش اتعتمد ✓',
            'disputed' => 'اعتراضك وصل للإدارة ⚠️',
            _ => 'اتسجّل تأكيدك ✓',
          }),
        ),
      );
      nav.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'ورقة الماتش', subtitle: 'MATCH SHEET', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<MatchSheet>(
              future: _sheet,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'انت لعبت في الماتش ده — النتيجة والأهداف دي صح؟ رأيك بيحمي نقط الناس من الغش.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 12),
                    MatchSheetView(match: m, events: snap.data!.events, players: snap.data!.players),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  _button('❌ فيه غلط', AppColors.danger, () => _send(false)),
                  const SizedBox(width: 8),
                  _button('✅ كله صح', AppColors.accent, () => _send(true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, Color color, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        color: _busy ? AppColors.neutral500 : color,
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        child: Text(label, style: AppText.h(14, color: AppColors.white)),
      ),
    ),
  );
}
