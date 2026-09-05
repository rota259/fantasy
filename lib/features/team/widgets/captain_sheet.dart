import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/initials_tile.dart';
import '../../players/data/models/player.dart';

/// شيت اختيار الكابتن من لاعيبة التشكيلة.
Future<void> showCaptainSheet(
  BuildContext context,
  List<Player> players,
  String? captainId,
  void Function(String id) onPick,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.black,
            child: Text('اختر الكابتن', style: AppText.h(16, color: AppColors.white)),
          ),
          for (final p in players)
            GestureDetector(
              onTap: () {
                onPick(p.id);
                Navigator.pop(ctx);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    InitialsTile(p.initials),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: AppText.h(14)),
                          Text('${p.team} · ${p.positionAr}',
                              style: AppText.body(10, color: AppColors.neutral700)),
                        ],
                      ),
                    ),
                    if (p.id == captainId)
                      Text('×2', style: AppText.h(18, color: AppColors.accent)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
