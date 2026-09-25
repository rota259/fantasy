import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// اختيار أهداف فريق: − رقم +
class ScorePicker extends StatelessWidget {
  const ScorePicker({super.key, required this.team, required this.value, required this.onChanged});

  final String team;
  final int value;
  final ValueChanged<int>? onChanged; // null = مقفول

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Column(
      children: [
        Text(
          team,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.h(13, color: AppColors.accent),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _btn('−', enabled && value > 0 ? () => onChanged!(value - 1) : null),
            SizedBox(
              width: 56,
              child: Text('$value', textAlign: TextAlign.center, style: AppText.h(40)),
            ),
            _btn('+', enabled && value < 20 ? () => onChanged!(value + 1) : null),
          ],
        ),
      ],
    );
  }

  Widget _btn(String t, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: onTap == null ? AppColors.divider : AppColors.black, width: 2),
      ),
      child: Text(t, style: AppText.h(18, color: onTap == null ? AppColors.neutral400 : AppColors.ink)),
    ),
  );
}
