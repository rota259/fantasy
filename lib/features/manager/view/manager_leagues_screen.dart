import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../leagues/data/models/league.dart';
import '../../../core/widgets/motion.dart';

/// (مدير) كل دوريات اليوزرز: مين عمله وكام عضو — واحذف أي دوري مخالف (مراهنات مثلًا).
class ManagerLeaguesScreen extends StatefulWidget {
  const ManagerLeaguesScreen({super.key});

  @override
  State<ManagerLeaguesScreen> createState() => _ManagerLeaguesScreenState();
}

class _ManagerLeaguesScreenState extends State<ManagerLeaguesScreen> {
  late final LeaguesRepository _repo = context.read<LeaguesRepository>();
  late Future<List<League>> _future = _repo.fetchAll();
  String _q = '';

  void _reload() => setState(() {
    _future = _repo.fetchAll();
  });

  /// الدوري العام: كل اليوزرز أوتوماتيك بترتيب النقط (والتعادل بالامتلاك الأقل).
  Future<void> _createGlobal() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.createGlobalLeague('دوري الخماسي العام');
      _reload();
      messenger.showSnackBar(const SnackBar(content: Text('اتعمل الدوري العام واتبعت إشعار للكل ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _delete(League l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف الدوري', style: AppText.h(16)),
        content: Text(
          '«${l.name}» بتاع ${l.ownerName ?? '—'} — ${l.memberCount} عضو هيخرجوا منه.',
          style: AppText.body(13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.deleteLeague(l.id);
      _reload();
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
          Masthead(title: 'الدوريات', subtitle: 'ADMIN · LEAGUES', onBack: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.line, width: 1.2),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _q = v.trim()),
                style: AppText.h(14),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  hintText: 'دوّر باسم الدوري أو صاحبه',
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<League>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                final list = snap.data!
                    .where((l) => _q.isEmpty || l.name.contains(_q) || (l.ownerName ?? '').contains(_q))
                    .toList();
                final hasGlobal = snap.data!.any((l) => l.isGlobal);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (!hasGlobal)
                      Pressable(
                        onTap: _createGlobal,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                          alignment: Alignment.center,
                          child: Text(
                            '🏆 اعمل الدوري العام (كل اليوزرز)',
                            style: AppText.h(14, color: AppColors.white),
                          ),
                        ),
                      ),
                    if (list.isEmpty) Text('مفيش دوريات', style: AppText.body(12, color: AppColors.neutral600)),
                    for (final l in list) _row(l),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(League l) => Container(
    padding: const EdgeInsets.symmetric(vertical: 11),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.divider)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.name, style: AppText.h(14)),
              Text(
                l.isGlobal
                    ? 'العام · كل اليوزرز أوتوماتيك'
                    : '${l.typeLabel} · ${l.memberCount} عضو · صاحبه: ${l.ownerName ?? '—'}',
                style: AppText.body(10, color: AppColors.neutral700),
              ),
            ],
          ),
        ),
        if (!l.isGlobal)
          Pressable(
            onTap: () {
              Clipboard.setData(ClipboardData(text: l.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اتنسخ الكود ✓')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
              child: Text(l.inviteCode, style: AppText.h(12, color: AppColors.white, spacingEm: 0.1)),
            ),
          ),
        const SizedBox(width: 10),
        Pressable(
          onTap: () => _delete(l),
          child: Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
        ),
      ],
    ),
  );
}
