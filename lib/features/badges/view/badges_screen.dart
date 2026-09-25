import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/badge_catalog.dart';
import '../data/badges_repository.dart';
import '../data/models/user_badge.dart';
import '../widgets/badge_sheet.dart';
import '../widgets/badge_tile.dart';

/// كل الإنجازات متقسّمة مجموعات — اللي اتاخد ملوّن، والسرّي مخفي لحد ما يتاخد.
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key, required this.userId, required this.userName});

  final String userId;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'إنجازاتي', subtitle: 'BADGES', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<UserBadge>>(
              future: context.read<BadgesRepository>().forUser(userId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                final mine = {for (final b in snap.data!) b.key: b};
                final earned = mine.values.where((b) => b.earned).length;
                final groups = <String, List<BadgeDef>>{};
                for (final d in BadgeCatalog.all) {
                  groups.putIfAbsent(d.group, () => []).add(d);
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    Container(
                      color: AppColors.black,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'خدت $earned من ${BadgeCatalog.all.length} شارة — كل شارة ليها ٣ مستويات 🥉🥈🥇',
                        style: AppText.h(13, color: AppColors.white),
                      ),
                    ),
                    for (final g in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: Text(g.key, style: AppText.kicker(color: AppColors.accent)),
                      ),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        childAspectRatio: 0.72,
                        children: [
                          for (final d in g.value)
                            BadgeTile(
                              def: d,
                              tier: mine[d.key]?.tier ?? 0,
                              onTap: () => showBadgeSheet(context, d, mine[d.key], userName),
                            ),
                        ],
                      ),
                    ],
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
