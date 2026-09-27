import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../claims/data/claims_repository.dart';
import '../../claims/data/models/player_claim.dart';
import '../../../core/widgets/motion.dart';

/// (مدير) طلبات توثيق اللاعيبة: اتأكد (مكالمة/واتساب) ووافق أو ارفض.
class ManagerClaimsScreen extends StatefulWidget {
  const ManagerClaimsScreen({super.key});

  @override
  State<ManagerClaimsScreen> createState() => _ManagerClaimsScreenState();
}

class _ManagerClaimsScreenState extends State<ManagerClaimsScreen> {
  late final ClaimsRepository _repo = context.read<ClaimsRepository>();
  late Future<List<PlayerClaim>> _future = _repo.pending();

  Future<void> _review(PlayerClaim c, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.review(c.id, approve);
      messenger.showSnackBar(SnackBar(content: Text(approve ? 'اتوثّق ${c.playerName} ✓' : 'اترفض الطلب')));
      setState(() {
        _future = _repo.pending();
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
          Masthead(title: 'توثيق اللاعيبة', subtitle: 'ADMIN · CLAIMS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<PlayerClaim>>(
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
                return ListView(padding: EdgeInsets.zero, children: [for (final c in snap.data!) _row(c)]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(PlayerClaim c) {
    final phone = c.phone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${c.userName.isEmpty ? 'يوزر' : c.userName} بيقول إنه ${c.playerName}', style: AppText.h(14)),
          Text('${c.team}${phone != null ? ' · $phone' : ''}', style: AppText.body(11, color: AppColors.neutral700)),
          if (c.note != null) Text('«${c.note}»', style: AppText.body(12)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (phone != null && phone.isNotEmpty) ...[
                _btn('اتصل', AppColors.black, () => Launchers.call(phone)),
                const SizedBox(width: 6),
              ],
              _btn('وافق ✓', AppColors.accent, () => _review(c, true)),
              const SizedBox(width: 6),
              _btn('ارفض', AppColors.danger, () => _review(c, false)),
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
