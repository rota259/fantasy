import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/data/models/app_user.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../data/admin_repository.dart';

/// (مدير) مين نزّل تشكيلته للماتش ومين لأ + تذكير اللي لسه.
class MatchPicksSection extends StatefulWidget {
  const MatchPicksSection({super.key, required this.match});
  final GameMatch match;

  @override
  State<MatchPicksSection> createState() => _MatchPicksSectionState();
}

class _MatchPicksSectionState extends State<MatchPicksSection> {
  late Future<(List<AppUser>, Set<String>)> _future = _load();
  bool _sending = false;

  Future<(List<AppUser>, Set<String>)> _load() async {
    final repo = context.read<AdminRepository>();
    final users = (await repo.fetchUsers()).where((u) => !u.isManager).toList();
    return (users, await repo.pickedUserIds(widget.match.id));
  }

  Future<void> _remind(List<AppUser> missing) async {
    final m = widget.match;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await context.read<AdminRepository>().notify(
        title: 'متنساش تشكيلتك ⏰',
        body: '${m.teamA} ضد ${m.teamB} — بتقفل ${arabicWeekday(m.deadline)} ${arabicTime(m.deadline)}',
        kind: 'lineup',
        matchId: m.id,
        userIds: [for (final u in missing) u.id],
      );
      messenger.showSnackBar(SnackBar(content: Text('اتبعت تذكير لـ ${missing.length} ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل الإرسال: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('تعذّر التحميل', style: AppText.body(12, color: AppColors.danger));
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final (users, picked) = snap.data!;
        final done = users.where((u) => picked.contains(u.id)).toList();
        final missing = users.where((u) => !picked.contains(u.id)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('نزّل تشكيلته ${done.length} من ${users.length}', style: AppText.h(15))),
                GestureDetector(
                  onTap: () => setState(() {
                    _future = _load();
                  }),
                  child: const Icon(Icons.refresh, size: 20, color: AppColors.neutral700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (missing.isNotEmpty && !widget.match.isLocked)
              GestureDetector(
                onTap: _sending ? null : () => _remind(missing),
                child: Container(
                  color: _sending ? AppColors.neutral500 : AppColors.accent,
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  child: Text('⏰ ذكّر اللي لسه (${missing.length})', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            const SizedBox(height: 12),
            for (final u in missing) _row(u, false),
            for (final u in done) _row(u, true),
          ],
        );
      },
    );
  }

  Widget _row(AppUser u, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? AppColors.accent : AppColors.neutral400,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(u.name.isEmpty ? u.email : u.name, style: AppText.h(13))),
          Text(done ? 'نزّل' : 'لسه', style: AppText.body(11, color: done ? AppColors.accent : AppColors.neutral600)),
        ],
      ),
    );
  }
}
