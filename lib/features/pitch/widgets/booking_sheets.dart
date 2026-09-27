import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../data/models/booking.dart';
import '../data/models/venue.dart';
import '../../../core/widgets/motion.dart';

String slotText(DateTime day, int hour) => '${day.day}/${day.month} الساعة ${formatHour(hour)}';

/// تأكيد قبل إرسال طلب الحجز. بيرجّع الملاحظة (ممكن فاضية) أو null لو اتلغى.
Future<String?> showBookingConfirmSheet(BuildContext context, Venue v, DateTime day, int hour) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => _ConfirmSheet(venue: v, day: day, hour: hour),
  );
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.venue, required this.day, required this.hour});
  final Venue venue;
  final DateTime day;
  final int hour;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('تأكيد طلب الحجز', style: AppText.h(17)),
              const SizedBox(height: 10),
              Text(v.name, style: AppText.h(15, color: AppColors.accent)),
              Text(slotText(widget.day, widget.hour), style: AppText.h(14)),
              Text('السعر: ${v.price} جنيه للساعة', style: AppText.body(12, color: AppColors.neutral700)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line, width: 1.2),
                ),
                child: TextField(
                  controller: _note,
                  style: AppText.h(13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'اسم فريقك / ملاحظة لصاحب الملعب (اختياري)',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'الحجز هيبقى معلّق ⏳ لحد ما صاحب الملعب يوافق.',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
              const SizedBox(height: 14),
              _btn('ابعت طلب الحجز', AppColors.accent, () => Navigator.pop(context, _note.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// بعد الإرسال: الحجز معلّق + تواصل مع الملعب.
Future<void> showBookingSentSheet(BuildContext context, Venue v, DateTime day, int hour) {
  final phone = v.phone;
  final msg = 'السلام عليكم، طلبت حجز من تطبيق الخماسي: ${v.name} يوم ${slotText(day, hour)}. ممكن تأكّد الحجز؟';
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.hourglass_top, size: 40, color: Color(0xFFCA8A04)),
            const SizedBox(height: 8),
            Text('طلبك اتبعت ✓', textAlign: TextAlign.center, style: AppText.h(18)),
            const SizedBox(height: 4),
            Text(
              'الحجز معلّق لحد ما صاحب الملعب يأكّده، وهيوصلك إشعار أول ما يرد.',
              textAlign: TextAlign.center,
              style: AppText.body(12, color: AppColors.neutral700),
            ),
            if (phone != null && phone.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _btn('📞 اتصل بالملعب', AppColors.black, () => Launchers.call(phone))),
                  const SizedBox(width: 8),
                  Expanded(child: _btn('واتساب', const Color(0xFF16A34A), () => Launchers.whatsapp(phone, msg))),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _btn('تمام', AppColors.accent, () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}

Widget _btn(String label, Color color, VoidCallback onTap) => Pressable(
  onTap: onTap,
  child: Container(
    decoration: BoxDecoration(color: color, borderRadius: AppRadius.md),
    padding: const EdgeInsets.all(12),
    alignment: Alignment.center,
    child: Text(label, style: AppText.h(13, color: AppColors.white)),
  ),
);
