import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'share_card.dart';

/// معاينة كارت story + زرار شيّر (الكارت لازم يترسم عشان يتصوّر، فبنعرضه الأول).
Future<void> showStoryShare(BuildContext context, {required Widget card, required String text}) {
  final key = GlobalKey();
  return showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: RepaintBoundary(key: key, child: card),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: () => ShareCard.share(key, text),
                icon: const Icon(Icons.ios_share),
                label: const Text('شيّر'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => Navigator.pop(c),
                child: const Text('قفل'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
