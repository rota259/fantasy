import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/maps_link.dart';
import '../../../core/widgets/motion.dart';

part 'venue_location_field_sections.dart';

/// (صاحب الملعب) موقع الملعب: لينك جوجل مابس — زرار «الموقع» بيفتحه في تطبيق الخرايط.
class VenueLocationField extends StatefulWidget {
  const VenueLocationField({super.key, required this.link});

  final TextEditingController link;

  @override
  State<VenueLocationField> createState() => _VenueLocationFieldState();
}

class _VenueLocationFieldState extends State<VenueLocationField> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  String? _msg;
  bool _ok = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.line, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.link,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _check(),
                  onChanged: (_) => setState(() => _msg = null),
                  style: AppText.body(12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintText: 'لينك جوجل مابس (maps.app.goo.gl/…)',
                  ),
                ),
              ),
              IconButton(tooltip: 'لصق', onPressed: _paste, icon: const Icon(Icons.content_paste)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _msg ?? 'من جوجل مابس: افتح الملعب ← مشاركة ← نسخ اللينك، والصقه هنا',
                style: AppText.body(
                  11,
                  color: _msg == null ? AppColors.neutral600 : (_ok ? AppColors.accent : AppColors.danger),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Pressable(
              onTap: _check,
              child: Container(
                decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text('تحقق', style: AppText.h(12, color: AppColors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
