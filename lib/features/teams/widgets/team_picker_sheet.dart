import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/team.dart';
import '../data/teams_repository.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// (مدير) اختيار فريق — بيرجّع الاسم. [opponents]: فرقي + فرق الكباتن التانيين في منطقتي (الخصم بيأكّد النتيجة).
Future<String?> showTeamPicker(BuildContext context, String userId, {bool opponents = false, int? zoneId}) =>
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (_) => SafeArea(
        child: FutureBuilder<List<Team>>(
          future: _load(context.read<TeamsRepository>(), userId, opponents, zoneId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return SizedBox(height: 160, child: const SkeletonList());
            }
            if (snap.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text('لسه معملتش فرق — اعملها من "فرقي" في حسابك', style: AppText.body(13)),
              );
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final t in snap.data!)
                  ListTile(
                    leading: Icon(Icons.shield_outlined, color: AppColors.accent),
                    title: Text(t.name, style: AppText.h(14)),
                    subtitle: t.ownerId == userId
                        ? null
                        : Text('كابتن: ${t.ownerName ?? '—'} · هيأكّد النتيجة', style: AppText.body(11)),
                    onTap: () => Navigator.pop(context, t.name),
                  ),
              ],
            );
          },
        ),
      ),
    );

Future<List<Team>> _load(TeamsRepository repo, String me, bool opponents, int? zone) async {
  if (!opponents) return repo.mine(me);
  final all = await repo.all();
  bool other(Team t) => t.ownerId != null && t.ownerId != me && (zone == null || t.zoneId == zone);
  return [...all.where((t) => t.ownerId == me), ...all.where(other)];
}
