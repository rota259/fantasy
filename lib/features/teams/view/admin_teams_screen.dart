import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../zones/data/zone.dart';
import '../../zones/data/zones_repository.dart';
import '../../zones/widgets/zone_picker_sheet.dart';
import '../data/team.dart';
import '../data/teams_repository.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// (أدمن) كل الفرق: المنطقة والصاحب — الفرق القديمة من غير منطقة حدّدلها منطقتها من هنا.
class AdminTeamsScreen extends StatefulWidget {
  const AdminTeamsScreen({super.key});

  @override
  State<AdminTeamsScreen> createState() => _AdminTeamsScreenState();
}

class _AdminTeamsScreenState extends State<AdminTeamsScreen> {
  late final TeamsRepository _repo = context.read<TeamsRepository>();
  late Future<(List<Team>, List<Zone>)> _future = _load();

  Future<(List<Team>, List<Zone>)> _load() => (_repo.all(), context.read<ZonesRepository>().fetchAll()).wait;

  Future<void> _setZone(Team t) async {
    final z = await showZonePicker(context);
    if (z == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setZone(t.id, z.id);
      messenger.showSnackBar(SnackBar(content: Text('«${t.name}» بقى في ${z.label} ✓')));
      setState(() {
        _future = _load();
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
          Masthead(title: 'الفرق', subtitle: 'ADMIN · TEAMS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<(List<Team>, List<Zone>)>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return const SkeletonList();
                final (teams, zones) = snap.data!;
                final byId = {for (final z in zones) z.id: z};
                // اللي من غير منطقة الأول
                final sorted = [...teams]
                  ..sort((a, b) => (a.zoneId == null ? 0 : 1).compareTo(b.zoneId == null ? 0 : 1));
                return ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [for (final t in sorted) _row(t, byId[t.zoneId])],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Team t, Zone? zone) => Pressable(
    behavior: HitTestBehavior.opaque,
    onTap: () => _setZone(t),
    child: Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: AppDecor.tile,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: AppText.h(14)),
                Text(
                  '${zone?.label ?? '⚠️ من غير منطقة'} · ${t.ownerName ?? 'الأدمن'}',
                  style: AppText.body(11, color: zone == null ? AppColors.danger : AppColors.neutral700),
                ),
              ],
            ),
          ),
          Text('المنطقة ›', style: AppText.h(12, color: AppColors.accent)),
        ],
      ),
    ),
  );
}
