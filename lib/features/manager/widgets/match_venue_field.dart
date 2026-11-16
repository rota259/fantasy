import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../matches/data/models/match_place.dart';
import '../../pitch/data/models/venue.dart';
import '../../pitch/data/venues_repository.dart';
import '../../../core/widgets/net_image.dart';

part 'match_venue_field_sheet.dart';

/// حقل «الملعب» في الماتش: بيفتح شيت تختار منه ملعب من الأبلكيشن أو تكتب اسم وعنوان.
class MatchVenueField extends StatelessWidget {
  const MatchVenueField({super.key, required this.place, required this.zoneId, required this.onChanged});

  final MatchPlace? place;
  final int? zoneId;
  final ValueChanged<MatchPlace> onChanged;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () async {
      final p = await showModalBottomSheet<MatchPlace>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.bg,
        builder: (_) => _VenueSheet(zoneId: zoneId, initial: place),
      );
      if (p != null) onChanged(p);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.stadium_outlined, size: 18, color: AppColors.neutral700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              place?.label ?? 'الملعب (اختاره أو اكتب اسمه وعنوانه)',
              style: AppText.h(13, color: place == null ? AppColors.neutral600 : AppColors.ink),
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    ),
  );
}
