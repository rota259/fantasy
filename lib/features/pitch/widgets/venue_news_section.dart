import 'package:flutter/material.dart';
import '../../../core/app_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../data/models/venue.dart';
import '../data/models/venue_extras.dart';
import '../data/venues_repository.dart';
import 'venue_post_sheet.dart';

/// أخبار الملعب: «اتجدد — قيّمه من جديد» + آخر الإعلانات + زرار الإعلان لصاحب الملعب.
class VenueNewsSection extends StatefulWidget {
  const VenueNewsSection({super.key, required this.venue, required this.isOwner});

  final Venue venue;
  final bool isOwner;

  @override
  State<VenueNewsSection> createState() => _VenueNewsSectionState();
}

class _VenueNewsSectionState extends State<VenueNewsSection> {
  late final VenuesRepository _repo = context.read<VenuesRepository>();
  late Future<List<VenueUpdate>> _future = _repo.updates(widget.venue.id);

  late bool _requested =
      widget.venue.verifyRequestedAt != null && DateTime.now().difference(widget.venue.verifyRequestedAt!).inHours < 24;

  /// صاحب ملعب مش موثّق: يطلب التوثيق (الأدمن ومشرف المنطقة يوصلهم إشعار).
  Future<void> _requestVerify() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.requestVerification(widget.venue.id);
      setState(() => _requested = true);
      messenger.showSnackBar(const SnackBar(content: Text('الطلب اتبعت ✓ — الإدارة هتكلّمك تتأكد')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _verifyBox() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'ملعبك لسه مش موثّق — الموثّق بيعمل بطولات ويعلن لأهل المنطقة.',
        style: AppText.body(11, color: AppColors.neutral700),
      ),
      const SizedBox(height: 6),
      _requested
          ? Text('⏳ طلب التوثيق اتبعت — الإدارة هتكلّمك', style: AppText.h(12, color: AppColors.accent700))
          : FilledButton.icon(
              onPressed: _requestVerify,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('اطلب توثيق الملعب'),
            ),
    ],
  );

  Future<void> _post() async {
    final r = await showVenuePostSheet(context);
    if (r == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.postUpdate(widget.venue.id, r.$1, r.$2);
      setState(() => _future = _repo.updates(widget.venue.id));
      messenger.showSnackBar(const SnackBar(content: Text('اتبعت الإعلان لأهل المنطقة ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    final fresh = v.renovatedAt != null && DateTime.now().difference(v.renovatedAt!).inDays < 30;
    return FutureBuilder<List<VenueUpdate>>(
      future: _future,
      builder: (context, snap) {
        final list = snap.data ?? const <VenueUpdate>[];
        if (list.isEmpty && !fresh && !widget.isOwner) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fresh)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent100,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: Text(
                    '🏟️ الملعب اتجدد ${v.renovatedAt!.day}/${v.renovatedAt!.month} — التقييم بدأ من الأول، جرّبه وقيّمه',
                    style: AppText.h(12, color: AppColors.accent800),
                  ),
                ),
              if (list.isNotEmpty) ...[
                Text('أخبار الملعب', style: AppText.h(15)),
                for (final u in list.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: AppDecor.softDivider,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.isRenovation ? '🏟️ ' : '📣 ', style: AppText.body(13)),
                        Expanded(child: Text(u.body, style: AppText.body(12))),
                        Text(
                          '${u.createdAt.day}/${u.createdAt.month}',
                          style: AppText.body(10, color: AppColors.neutral600),
                        ),
                      ],
                    ),
                  ),
              ],
              if (widget.isOwner)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: v.verified || !kVenueVerify
                      ? OutlinedButton.icon(
                          onPressed: _post,
                          icon: const Icon(Icons.campaign_outlined),
                          label: const Text('أعلن عن تعديل أو تجديد'),
                        )
                      : _verifyBox(),
                ),
            ],
          ),
        );
      },
    );
  }
}
