import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';

/// مرشّح واحد (هدف/تصدّي): اللاعب + لينك الفيديو.
class AwardCandidate {
  AwardCandidate() : link = TextEditingController();
  String? playerId;
  final TextEditingController link;
  void dispose() => link.dispose();
}

/// (مدير) حقل مرشّح: اختيار اللاعب + لينك الفيديو + حذف.
class AwardCandidateField extends StatelessWidget {
  const AwardCandidateField({
    super.key,
    required this.index,
    required this.candidate,
    required this.players,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final AwardCandidate candidate;
  final List<Player> players;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('مرشّح ${index + 1}', style: AppText.kicker(color: AppColors.accent)),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: AppColors.danger),
              ),
            ],
          ),
          DropdownButton<String>(
            value: players.any((p) => p.id == candidate.playerId) ? candidate.playerId : null,
            isExpanded: true,
            hint: Text('اختار اللاعب', style: AppText.body(13)),
            items: [
              for (final p in players)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} · ${p.team}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) {
              candidate.playerId = v;
              onChanged();
            },
          ),
          TextField(
            controller: candidate.link,
            keyboardType: TextInputType.url,
            style: AppText.body(13),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'لينك الفيديو (يوتيوب / تيك توك / إنستجرام / درايف)',
            ),
          ),
        ],
      ),
    );
  }
}
