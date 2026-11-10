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
import '../../../core/widgets/fx/skeleton.dart';

part 'manager_leagues_screen_sections.dart';

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
                if (!snap.hasData) return const SkeletonList();
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
                          child: Text('اعمل الدوري العام (كل اليوزرز)', style: AppText.h(14, color: AppColors.white)),
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
}
