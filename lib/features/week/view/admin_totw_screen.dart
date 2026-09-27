import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/models/totw_candidates.dart';
import '../data/week_repository.dart';
import '../data/week_window.dart';
import '../../../core/widgets/motion.dart';

/// (أدمن) تشكيلات الجولة لكل منطقة: النظام بيقترح الأعلى نقط، والأدمن يراجع ويعتمد → تنزل لأهل المنطقة.
class AdminTotwScreen extends StatefulWidget {
  const AdminTotwScreen({super.key});

  @override
  State<AdminTotwScreen> createState() => _AdminTotwScreenState();
}

class _AdminTotwScreenState extends State<AdminTotwScreen> {
  late final WeekRepository _repo = context.read<WeekRepository>();
  WeekWindow _window = WeekWindow.current().previous; // آخر جولة خلصت
  late Future<List<TotwCandidates>> _future = _repo.candidates(_window);
  final _picked = <int, Set<String>>{}; // المنطقة → الخمسة المختارين

  void _load(WeekWindow w) => setState(() {
    _window = w;
    _picked.clear();
    _future = _repo.candidates(w);
  });

  Future<void> _publish(TotwCandidates z, Set<String> ids) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.publish(_window, z.zoneId, ids.toList());
      messenger.showSnackBar(SnackBar(content: Text('اتنشرت تشكيلة ${z.zoneLabel} ✓')));
      _load(_window);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canNext = _window.next.isFinal();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'تشكيلات الجولة',
            subtitle: _window.label,
            onBack: () => Navigator.pop(context),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pressable(
                  onTap: () => _load(_window.previous),
                  child: Text('‹  ', style: AppText.h(20, color: AppColors.white)),
                ),
                Pressable(
                  onTap: canNext ? () => _load(_window.next) : null,
                  child: Text('  ›', style: AppText.h(20, color: canNext ? AppColors.white : AppColors.neutral600)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TotwCandidates>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                if (snap.data!.isEmpty) {
                  return Center(child: Text('مفيش ماتشات في الجولة دي', style: AppText.body(13)));
                }
                return ListView(padding: const EdgeInsets.all(12), children: [for (final z in snap.data!) _zone(z)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _zone(TotwCandidates z) {
    final picked = _picked.putIfAbsent(z.zoneId, () => z.suggested.toSet());
    final (status, color) = z.published
        ? ('منشورة ✓', AppColors.accent)
        : z.tieOpen
        ? ('تصويت التعادل شغّال', AppColors.bronze)
        : ('جاهزة للاعتماد', AppColors.info);
    final ready = picked.length == 5 && !z.tieOpen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(z.zoneLabel, style: AppText.h(15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: AppRadius.sm),
                child: Text(status, style: AppText.h(10, color: AppColors.white)),
              ),
            ],
          ),
          if (z.tieOpen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'فيه تعادل على آخر ${z.slots} مكان — اليوزرز بيصوّتوا، اعتمد بعد ما التصويت يخلص.',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ),
          for (final p in z.candidates)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: picked.contains(p.id),
              onChanged: (on) => setState(() {
                if (on == true && picked.length < 5) {
                  picked.add(p.id);
                } else {
                  picked.remove(p.id);
                }
              }),
              title: Text('${p.name} · ${p.points} نقطة', style: AppText.h(13)),
              subtitle: Text(
                '${p.team}${z.tieWinners.contains(p.id) ? ' · 🗳 كسب التصويت' : ''}',
                style: AppText.body(10),
              ),
            ),
          const SizedBox(height: 6),
          Pressable(
            onTap: ready ? () => _publish(z, picked) : null,
            child: Container(
              decoration: BoxDecoration(
                color: ready ? AppColors.accent : AppColors.neutral400,
                borderRadius: AppRadius.md,
              ),
              padding: const EdgeInsets.all(11),
              alignment: Alignment.center,
              child: Text(
                '${z.published ? 'حدّث' : 'اعتمد وانشر'} (${picked.length}/5)',
                style: AppText.h(13, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
