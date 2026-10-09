import 'package:flutter/material.dart';
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

/// (أدمن) بلاغات المراهنات: حقّق ← اتثبت (بان نهائي من «المستخدمين») أو مش صحيح.
class AdminBettingScreen extends StatefulWidget {
  const AdminBettingScreen({super.key});

  @override
  State<AdminBettingScreen> createState() => _AdminBettingScreenState();
}

class _AdminBettingScreenState extends State<AdminBettingScreen> {
  late final FairPlayRepository _repo = context.read<FairPlayRepository>();
  late Future<List<BettingReport>> _future = _repo.adminReports();

  static const _labels = {
    'open': ('جديد', Color(0xFFD32F2F)),
    'investigating': ('بيتحقق فيه', Color(0xFFE08A00)),
    'proven': ('اتثبت — بان', Color(0xFF1B1B1B)),
    'dismissed': ('مش صحيح', Color(0xFF7A7A7A)),
  };

  Future<void> _set(BettingReport r, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setStatus(r.id, status);
      setState(() => _future = _repo.adminReports());
      if (status == 'proven' && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('اتثبت — اعمل بان للحساب من «المستخدمين» (إيقاف)'),
            action: SnackBarAction(
              label: 'المستخدمين',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerUsersScreen())),
            ),
          ),
        );
      }
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
          Masthead(title: 'بلاغات المراهنات', subtitle: 'ADMIN · FAIR PLAY', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<List<BettingReport>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const SkeletonList();
                final list = snap.data ?? const <BettingReport>[];
                if (list.isEmpty) {
                  return Center(
                    child: Text('مفيش بلاغات ✓', style: AppText.body(13, color: AppColors.neutral600)),
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

  Widget _card(BettingReport r) {
    final (label, color) = _labels[r.status] ?? ('—', AppColors.neutral500);
    final closed = r.status == 'proven' || r.status == 'dismissed';
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('على: ${r.suspect}', style: AppText.h(14))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: AppRadius.sm),
                child: Text(label, style: AppText.h(10, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.details, style: AppText.body(13)),
          const SizedBox(height: 6),
          Text(
            'من ${r.reporter} · ${r.zone} · ${r.createdAt.day}/${r.createdAt.month}',
            style: AppText.body(11, color: AppColors.neutral700),
          ),
          if (!closed)
            Wrap(
              spacing: 8,
              children: [
                if (r.status == 'open')
                  TextButton(onPressed: () => _set(r, 'investigating'), child: const Text('🔍 بحقّق')),
                TextButton(
                  onPressed: () => _set(r, 'proven'),
                  child: Text('⛔ اتثبت', style: AppText.h(13, color: AppColors.danger)),
                ),
                TextButton(onPressed: () => _set(r, 'dismissed'), child: const Text('مش صحيح')),
              ],
            ),
        ],
      ),
    );
  }
}
