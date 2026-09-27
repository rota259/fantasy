import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/integrity_repository.dart';
import '../data/models/organizer_request.dart';
import '../../../core/widgets/motion.dart';

/// (أدمن) طلبات "عايز أنظّم ماتشات": اتصل واتأكد، ووافق أو ارفض.
class AdminOrganizersScreen extends StatefulWidget {
  const AdminOrganizersScreen({super.key});

  @override
  State<AdminOrganizersScreen> createState() => _AdminOrganizersScreenState();
}

class _AdminOrganizersScreenState extends State<AdminOrganizersScreen> {
  late final IntegrityRepository _repo = context.read<IntegrityRepository>();
  late Future<List<OrganizerRequest>> _future = _repo.pendingOrganizerRequests();

  Future<void> _review(OrganizerRequest r, bool approve) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.reviewOrganizerRequest(r.id, approve);
      messenger.showSnackBar(SnackBar(content: Text(approve ? '${r.userName} بقى مدير ✓' : 'اترفض الطلب')));
      setState(() {
        _future = _repo.pendingOrganizerRequests();
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
          Masthead(title: 'طلبات المديرين', subtitle: 'ADMIN · ORGANIZERS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<OrganizerRequest>>(
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

  Widget _row(OrganizerRequest r) {
    final phone = r.phone;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.userName.isEmpty ? 'يوزر' : r.userName, style: AppText.h(14)),
          Text(
            [if (r.playerName != null) 'لاعب موثّق: ${r.playerName}', if (phone != null) phone].join(' · '),
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
              _btn('وافق ✓', AppColors.accent, () => _review(r, true)),
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
