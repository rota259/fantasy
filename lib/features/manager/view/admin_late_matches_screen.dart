import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/late_match_request.dart';
import '../../matches/widgets/match_format.dart';

/// (أدمن) طلبات ماتشات بعد الديدلاين من مديرين المناطق: وافق (الماتش بيتعمل باسم المدير) أو ارفض.
class AdminLateMatchesScreen extends StatefulWidget {
  const AdminLateMatchesScreen({super.key});

  @override
  State<AdminLateMatchesScreen> createState() => _AdminLateMatchesScreenState();
}

class _AdminLateMatchesScreenState extends State<AdminLateMatchesScreen> {
  late final MatchesRepository _repo = context.read<MatchesRepository>();
  late Future<List<LateMatchRequest>> _future = _repo.pendingLateMatches();

  Future<void> _review(LateMatchRequest r, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.reviewLateMatch(r.id, approve);
      messenger.showSnackBar(SnackBar(content: Text(approve ? 'الماتش اتضاف ✓' : 'اترفض الطلب')));
      setState(() {
        _future = _repo.pendingLateMatches();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'ماتشات متأخرة', subtitle: 'ADMIN · LATE MATCHES', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<LateMatchRequest>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                if (snap.data!.isEmpty) {
                  return Center(
                    child: Text('مفيش طلبات دلوقتي', style: AppText.body(13, color: AppColors.neutral600)),
                  );
                }
                return ListView(padding: EdgeInsets.zero, children: [for (final r in snap.data!) _row(r)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(LateMatchRequest r) {
    final phone = r.phone;
    final teams = r.teams.length == 2 ? '${r.teams[0]} × ${r.teams[1]}' : r.teams.join(' × ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(teams, style: AppText.h(14)),
          Text(
            '${arabicWeekday(r.dateTime)} ${r.dateTime.day}/${r.dateTime.month} · ${arabicTime(r.dateTime)}'
            ' · المدير: ${r.organizerName.isEmpty ? '—' : r.organizerName}',
            style: AppText.body(11, color: AppColors.neutral700),
          ),
          if (r.note != null) Text('«${r.note}»', style: AppText.body(12)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (phone != null && phone.isNotEmpty) ...[
                _btn('اتصل', AppColors.black, () => Launchers.call(phone)),
                const SizedBox(width: 6),
              ],
              _btn('ضيفه ✓', AppColors.accent, () => _review(r, true)),
              const SizedBox(width: 6),
              _btn('ارفض', AppColors.danger, () => _review(r, false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(String t, Color color, VoidCallback onTap) => Expanded(
    child: Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: color, borderRadius: AppRadius.md),
        padding: const EdgeInsets.all(9),
        alignment: Alignment.center,
        child: Text(t, style: AppText.h(12, color: AppColors.white)),
      ),
    ),
  );
}
