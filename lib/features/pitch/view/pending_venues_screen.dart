import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../data/models/venue_extras.dart';
import '../data/venues_repository.dart';

/// (أدمن أو مشرف المنطقة) طلبات توثيق الملاعب: كلّم صاحب الملعب واتأكد ← وثّق أو ارفض.
/// الموثّق بيعمل بطولات ويعلن لأهل المنطقة.
class PendingVenuesScreen extends StatefulWidget {
  const PendingVenuesScreen({super.key});

  @override
  State<PendingVenuesScreen> createState() => _PendingVenuesScreenState();
}

class _PendingVenuesScreenState extends State<PendingVenuesScreen> {
  late final VenuesRepository _repo = context.read<VenuesRepository>();
  late Future<List<PendingVenue>> _future = _repo.pending();

  Future<void> _decide(PendingVenue v, bool ok) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.verify(v.id, ok);
      setState(() => _future = _repo.pending());
      messenger.showSnackBar(SnackBar(content: Text(ok ? 'اتوثّق «${v.name}» ✓' : 'اترفض الطلب')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(
      children: [
        const StatusArea(),
        Masthead(title: 'توثيق الملاعب', subtitle: 'VENUE REQUESTS', onBack: () => Navigator.pop(context)),
        Expanded(
          child: FutureBuilder<List<PendingVenue>>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                );
              }
              if (!snap.hasData) return const SkeletonList();
              if (snap.data!.isEmpty) {
                return const Center(
                  child: EmptyState(icon: Icons.verified_outlined, title: 'مفيش طلبات توثيق', hint: 'كله تمام'),
                );
              }
              return ListView(
                padding: const EdgeInsets.only(top: 14, bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Text(
                      'كلّم صاحب الملعب واتأكد إن الملعب موجود وإنه صاحبه فعلًا — الموثّق بيعمل بطولات ويبعت إشعارات لأهل المنطقة.',
                      style: AppText.body(12, color: AppColors.neutral700),
                    ),
                  ),
                  for (final v in snap.data!) _tile(v),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _tile(PendingVenue v) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.all(14),
    decoration: AppDecor.tile,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(v.name, style: AppText.h(15)),
        if (v.address != null) Text(v.address!, style: AppText.body(12, color: AppColors.neutral700)),
        Text('صاحبه: ${v.ownerName ?? '—'}', style: AppText.body(12)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (v.ownerPhone != null)
              IconButton(onPressed: () => Launchers.call(v.ownerPhone!), icon: const Icon(Icons.call_outlined)),
            const Spacer(),
            TextButton(
              onPressed: () => _decide(v, false),
              child: Text('ارفض', style: AppText.h(13, color: AppColors.danger)),
            ),
            FilledButton(onPressed: () => _decide(v, true), child: const Text('وثّق')),
          ],
        ),
      ],
    ),
  );
}
