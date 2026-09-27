import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/launchers.dart';
import '../data/models/venue.dart';
import '../../../core/widgets/motion.dart';

/// أزرار التواصل مع الملعب: الموقع (لينك جوجل مابس الأدق) · اتصل · واتساب.
class VenueContactBar extends StatelessWidget {
  const VenueContactBar({super.key, required this.venue});
  final Venue venue;

  @override
  Widget build(BuildContext context) {
    final v = venue;
    final phone = v.phone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          if (v.mapsUrl?.isNotEmpty ?? false)
            _action(context, Icons.map_outlined, 'الموقع', () => Launchers.url(v.mapsUrl!))
          else if (v.hasLocation)
            _action(context, Icons.map_outlined, 'الموقع', () => Launchers.maps(v.lat!, v.lng!)),
          if (phone != null && phone.isNotEmpty) ...[
            _action(context, Icons.call_outlined, 'اتصل', () => Launchers.call(phone)),
            _action(
              context,
              Icons.chat_outlined,
              'واتساب',
              () => Launchers.whatsapp(phone, 'السلام عليكم، بسأل على حجز ملعب ${v.name}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label, Future<bool> Function() onTap) => Expanded(
    child: Pressable(
      onTap: () async {
        final messenger = ScaffoldMessenger.of(context);
        if (!await onTap()) messenger.showSnackBar(const SnackBar(content: Text('مقدرتش أفتحه على الموبايل ده')));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            Text(label, style: AppText.h(11)),
          ],
        ),
      ),
    ),
  );
}
