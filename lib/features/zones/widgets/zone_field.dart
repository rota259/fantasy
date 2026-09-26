import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/zone.dart';
import 'zone_picker_sheet.dart';

/// حقل "منطقتك" في الفورم — بيفتح اختيار المحافظة والمنطقة.
class ZoneField extends StatelessWidget {
  const ZoneField({super.key, required this.value, required this.onChanged});

  final Zone? value;
  final ValueChanged<Zone> onChanged;

  Future<void> _pick(BuildContext context) async {
    final z = await showZonePicker(context);
    if (z != null) onChanged(z);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('منطقتك', style: AppText.h(12)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value?.label ?? 'اختار المحافظة والمنطقة',
                    style: AppText.body(14, color: value == null ? AppColors.neutral600 : AppColors.ink),
                  ),
                ),
                Text('›', style: AppText.body(16, color: AppColors.neutral600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('هتشوف ماتشات منطقتك ونجومها، وتعمل تشكيلاتك منها.', style: AppText.body(11, color: AppColors.neutral700)),
      ],
    );
  }
}
