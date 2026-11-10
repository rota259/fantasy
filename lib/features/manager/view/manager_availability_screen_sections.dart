part of 'manager_availability_screen.dart';

extension _StatusSheetStateSections1 on _StatusSheetState {
  Widget _buildBody(BuildContext context) {
    final reasons = Availability.reasons(_status);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.player.name, style: AppText.h(16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in Availability.all)
                    Pressable(
                      onTap: () => _update(() => _status = a),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md,
                          color: _status == a ? AppColors.accent : null,
                          border: Border.all(color: _status == a ? AppColors.accent : AppColors.line, width: 1.4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Availability.icon(a),
                              size: 14,
                              color: _status == a ? AppColors.white : Availability.color(a),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              Availability.label(a),
                              style: AppText.h(12, color: _status == a ? AppColors.white : AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('ترشيحات السبب', style: AppText.kicker()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in reasons)
                      Pressable(
                        onTap: () => _update(() => _reason.text = r),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.md,
                            border: Border.all(color: AppColors.divider, width: 2),
                          ),
                          child: Text(r, style: AppText.body(11)),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppRadius.md,
                  border: Border.all(color: AppColors.line, width: 1.2),
                ),
                child: TextField(
                  controller: _reason,
                  style: AppText.h(13),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'السبب/التفاصيل (اختياري)',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: () {
                  final news = _status == Availability.ready ? null : _reason.text.trim();
                  widget.cubit.setAvailability(widget.player.id, _status, news);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text('احفظ الحالة', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
