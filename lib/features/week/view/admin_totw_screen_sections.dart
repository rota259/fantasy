part of 'admin_totw_screen.dart';

extension _AdminTotwScreenStateSections1 on _AdminTotwScreenState {
  Future<void> _publish(TotwCandidates z, Set<String> ids) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.publish(_window, z.zoneId, ids.toList());
      messenger.showSnackBar(SnackBar(content: Text('اتنشرت تشكيلة ${z.zoneLabel} ✓')));
      _load(_window);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Widget _zone(TotwCandidates z) {
    final picked = _picked.putIfAbsent(z.zoneId, () => z.suggested.toSet());
    final (status, color) = z.published
        ? ('منشورة ✓', AppColors.accent)
        : z.tieOpen
        ? ('تصويت التعادل شغّال', AppColors.bronze)
        : ('جاهزة للاعتماد', AppColors.info);
    final ready = picked.length == 5 && !z.tieOpen;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(z.zoneLabel, style: AppText.h(15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color, borderRadius: AppRadius.sm),
                child: Text(status, style: AppText.h(10, color: AppColors.white)),
              ),
            ],
          ),
          if (z.tieOpen)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'فيه تعادل على آخر ${z.slots} مكان — اليوزرز بيصوّتوا، اعتمد بعد ما التصويت يخلص.',
                style: AppText.body(11, color: AppColors.neutral700),
              ),
            ),
          for (final p in z.candidates)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: picked.contains(p.id),
              onChanged: (on) => _update(() {
                if (on == true && picked.length < 5) {
                  picked.add(p.id);
                } else {
                  picked.remove(p.id);
                }
              }),
              title: Text('${p.name} · ${p.points} نقطة', style: AppText.h(13)),
              subtitle: Text(
                '${p.team}${z.tieWinners.contains(p.id) ? ' · كسب التصويت' : ''}',
                style: AppText.body(10),
              ),
            ),
          const SizedBox(height: 6),
          Pressable(
            onTap: ready ? () => _publish(z, picked) : null,
            child: Container(
              decoration: BoxDecoration(
                color: ready ? AppColors.accent : AppColors.neutral400,
                borderRadius: AppRadius.md,
              ),
              padding: const EdgeInsets.all(11),
              alignment: Alignment.center,
              child: Text(
                '${z.published ? 'حدّث' : 'اعتمد وانشر'} (${picked.length}/5)',
                style: AppText.h(13, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
