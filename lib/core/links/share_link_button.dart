import 'package:flutter/material.dart';

import '../share/share_card.dart';
import '../theme/app_colors.dart';
import 'deep_links.dart';

/// زرار شير في الـ Masthead: نص + لينك بيفتح الصفحة دي في الأبلكيشن ([kind] = tournament · venue · match).
class ShareLinkButton extends StatelessWidget {
  const ShareLinkButton({super.key, required this.kind, required this.id, required this.text});

  final String kind;
  final String id;
  final String text;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'شيّر',
    icon: Icon(Icons.ios_share, color: AppColors.white, size: 20),
    onPressed: () => ShareCard.text('$text\n${DeepLinks.url(kind, id)}'),
  );
}
