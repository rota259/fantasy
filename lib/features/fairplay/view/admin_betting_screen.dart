import 'package:flutter/material.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../manager/view/manager_users_screen.dart';
import '../data/fairplay_repository.dart';

part 'admin_betting_screen_sections.dart';

/// (أدمن) بلاغات المراهنات: حقّق ← اتثبت (بان نهائي من «المستخدمين») أو مش صحيح.
class AdminBettingScreen extends StatefulWidget {
  const AdminBettingScreen({super.key});

  @override
  State<AdminBettingScreen> createState() => _AdminBettingScreenState();
}

class _AdminBettingScreenState extends State<AdminBettingScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final FairPlayRepository _repo = context.read<FairPlayRepository>();
  late Future<List<BettingReport>> _future = _repo.adminReports();

  static const _labels = {
    'open': ('جديد', Color(0xFFD32F2F)),
    'investigating': ('بيتحقق فيه', Color(0xFFE08A00)),
    'proven': ('اتثبت — بان', Color(0xFF1B1B1B)),
    'dismissed': ('مش صحيح', Color(0xFF7A7A7A)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'بلاغات المراهنات', subtitle: 'ADMIN · FAIR PLAY', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<BettingReport>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const SkeletonList();
                final list = snap.data ?? const <BettingReport>[];
                if (list.isEmpty) {
                  return Center(
                    child: EmptyState(
                      icon: Icons.verified_user_outlined,
                      title: 'مفيش بلاغات',
                      hint: 'محدش بلّغ عن مراهنات',
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  children: [for (final r in list) _card(r)],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
