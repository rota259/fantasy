import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/models/booking.dart';

/// مواعيد التشغيل: من ساعة لساعة (القفل ممكن بعد نص الليل).
class HoursPicker extends StatelessWidget {
  const HoursPicker({super.key, required this.open, required this.close, required this.onChanged});

  final int open;
  final int close;
  final void Function(int open, int close) onChanged;

  String _label(int h) => h >= 24 ? '${formatHour(h)} (بعد نص الليل)' : formatHour(h);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _box(
            'بيفتح',
            DropdownButton<int>(
              value: open,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text(formatHour(h)))],
              // لو الفتح اتغيّر، نظبط القفل يفضل بعده وجوه الحد (٢٤ ساعة بالكتير، ولحد 30).
              onChanged: (h) {
                if (h == null) return;
                final maxClose = h + 24 > 30 ? 30 : h + 24;
                onChanged(h, close <= h ? h + 1 : (close > maxClose ? maxClose : close));
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _box(
            'بيقفل',
            DropdownButton<int>(
              value: close,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (var h = open + 1; h <= (open + 24 > 30 ? 30 : open + 24); h++)
                  DropdownMenuItem(
                    value: h,
                    child: Text(_label(h), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (h) => h == null ? null : onChanged(open, h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _box(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.kicker()),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: child,
      ),
    ],
  );
}
