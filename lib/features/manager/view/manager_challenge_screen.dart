import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/challenge_setup_sheet.dart';
import '../../../core/app_mode.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../challenge/data/challenge_repository.dart';
import '../../matches/data/matches_repository.dart';
import '../../matches/data/models/game_match.dart';
import '../../matches/widgets/match_format.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'manager_challenge_screen_sections.dart';

/// تحدّي الجولة: مدير المنطقة بيختار ماتش من ماتشاته (واحد في الجولة)، والأدمن من أي ماتش.
/// يوزرز منطقة الماتش بس بيتوقّعوا — اللي يجيب فرق الأهداف صح ياخد +٥.
class ManagerChallengeScreen extends StatefulWidget {
  const ManagerChallengeScreen({super.key, this.organizerId});

  /// مدير المنطقة (ماتشاته بس) — null = الأدمن.
  final String? organizerId;

  @override
  State<ManagerChallengeScreen> createState() => _ManagerChallengeScreenState();
}

class _ManagerChallengeScreenState extends State<ManagerChallengeScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final MatchesRepository _matches = context.read<MatchesRepository>();
  late Future<List<GameMatch>> _future = _load();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'تحدّي الجولة',
            subtitle: widget.organizerId == null ? 'ADMIN · CHALLENGE' : 'CHALLENGE',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<GameMatch>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) return const SkeletonList();
                final list = snap.data!;
                final open = list.where((m) => !m.isChallenge).toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'اختار ماتش من ماتشاتك (ماتش واحد في الجولة)، وبعدها اختار أنواع التحدّي عليه: فرق الأهداف · '
                      'مين فيهم؟ · ٣ أسئلة · المعكوس — نوع واحد أو أكتر أو الأربعة. النقط بتتحسب بعد اعتماد الماتش.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                    const SizedBox(height: 12),
                    Pressable(
                      onTap: _busy || open.isEmpty ? null : () => _choose(open[Random().nextInt(open.length)]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _busy || open.isEmpty ? AppColors.neutral500 : AppColors.black,
                          borderRadius: AppRadius.md,
                        ),
                        padding: const EdgeInsets.all(13),
                        alignment: Alignment.center,
                        child: Text('اختار ماتش عشوائي', style: AppText.h(14, color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (list.isEmpty)
                      Text(
                        'مفيش ماتشات فاضل عليها أكتر من ساعتين',
                        style: AppText.body(12, color: AppColors.neutral600),
                      ),
                    for (final m in list) _row(m),
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
