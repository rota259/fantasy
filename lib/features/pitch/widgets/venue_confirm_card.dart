import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../integrity/widgets/note_dialog.dart';
import '../../matches/widgets/match_format.dart';
import '../data/models/venue_extras.dart';
import '../data/venues_repository.dart';

/// (صاحب الملعب) ماتشات خلصت في ملعبه: «اتلعب» = تأكيده (شرط للاعتماد زي الكباتن) · «ماتلعبش» = الإدارة تحكم.
class VenueConfirmCard extends StatefulWidget {
  const VenueConfirmCard({super.key, required this.venueId});
  final String venueId;

  @override
  State<VenueConfirmCard> createState() => _VenueConfirmCardState();
}

class _VenueConfirmCardState extends State<VenueConfirmCard> {
  late final VenuesRepository _repo = context.read<VenuesRepository>();
  late Future<List<VenueMatch>> _future = _load();

  Future<List<VenueMatch>> _load() => _repo.pendingMatches(widget.venueId).catchError((_) => const <VenueMatch>[]);

  Future<void> _answer(VenueMatch m, bool ok) async {
    String? note;
    if (!ok) {
      note = await showNoteDialog(context, title: 'الماتش ماتلعبش؟', hint: 'اكتب إيه اللي حصل');
      if (note == null || note.trim().isEmpty || !mounted) return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.confirmMatch(m.id, ok, note);
      setState(() => _future = _load());
      messenger.showSnackBar(SnackBar(content: Text(ok ? 'اتأكّد ✓' : 'وصل للإدارة')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<VenueMatch>>(
    future: _future,
    builder: (context, snap) {
      final list = snap.data ?? const <VenueMatch>[];
      if (list.isEmpty) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('🏟️ ماتشات اتلعبت في ملعبك؟', style: AppText.h(14, color: AppColors.accent800)),
            Text('تأكيدك شرط عشان النتيجة تتعتمد — زي الكباتن.', style: AppText.body(11, color: AppColors.neutral700)),
            for (final m in list)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${m.teams.first} ${m.scoreA ?? '-'} - ${m.scoreB ?? '-'} ${m.teams.last}\n'
                        '${arabicWeekday(m.dateTime)} ${arabicTime(m.dateTime)}',
                        style: AppText.body(12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _answer(m, false),
                      child: Text('ماتلعبش', style: AppText.h(12, color: AppColors.danger)),
                    ),
                    FilledButton(onPressed: () => _answer(m, true), child: const Text('اتلعب')),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
