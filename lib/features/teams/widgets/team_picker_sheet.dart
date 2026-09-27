import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/team.dart';
import '../data/teams_repository.dart';

/// (مدير) اختيار فريق من فرقي — بيرجّع الاسم.
Future<String?> showTeamPicker(BuildContext context, String userId) => showModalBottomSheet<String>(
  context: context,
  backgroundColor: AppColors.bg,
  builder: (_) => SafeArea(
    child: FutureBuilder<List<Team>>(
      future: context.read<TeamsRepository>().mine(userId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
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
                onTap: () => Navigator.pop(context, t.name),
              ),
          ],
        );
      },
    ),
  ),
);
