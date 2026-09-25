import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/box_field.dart';
import '../../points/points_engine.dart';
import '../cubit/manager_match_cubit.dart';

/// أنواع الأحداث اللي المدير يسجّلها (رجل المباراة بيتحسب من تصويت الجمهور لوحده).
const _eventTypes = [
  ('goal', 'جول'),
  ('assist', 'أسيست'),
  ('cleanSheet', 'شباك نظيفة'),
  ('save', 'تصدّي'),
  ('bonus', 'بونص'),
  ('yellowCard', 'أصفر'),
  ('redCard', 'أحمر'),
];

/// (مدير) تاب الأحداث: اختار اللاعب والنوع والدقيقة — والمتابعين بيوصلهم إشعار لوحده.
class MatchEventsSection extends StatefulWidget {
  const MatchEventsSection({super.key, required this.cubit, required this.state});

  final ManagerMatchCubit cubit;
  final ManagerMatchState state;

  @override
  State<MatchEventsSection> createState() => _MatchEventsSectionState();
}

class _MatchEventsSectionState extends State<MatchEventsSection> {
  String? _playerId;
  String _type = 'goal';
  final _minute = TextEditingController();

  @override
  void dispose() {
    _minute.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_playerId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('اختر اللاعب الأول')));
      return;
    }
    final err = await widget.cubit.addEvent(_playerId!, _type, int.tryParse(_minute.text));
    _minute.clear();
    messenger.showSnackBar(
      SnackBar(
        content: Text(err ?? 'اتسجّل الحدث ✓'),
        backgroundColor: err == null ? AppColors.accent : AppColors.danger,
        duration: Duration(milliseconds: err == null ? 1200 : 4000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
          child: DropdownButton<String>(
            value: _playerId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: Text('اختر اللاعب', style: AppText.body(13, color: AppColors.neutral600)),
            items: [
              for (final p in s.players)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} · ${p.team}', style: AppText.body(13)),
                ),
            ],
            onChanged: (v) => setState(() => _playerId = v),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in _eventTypes)
              GestureDetector(
                onTap: () => setState(() => _type = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _type == t.$1 ? AppColors.accent : null,
                    border: Border.all(color: _type == t.$1 ? AppColors.accent : AppColors.black, width: 2),
                  ),
                  child: Text(t.$2, style: AppText.h(12, color: _type == t.$1 ? AppColors.white : AppColors.ink)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        BoxField(controller: _minute, hint: 'الدقيقة (اختياري)', keyboard: TextInputType.number),
        GestureDetector(
          onTap: _add,
          child: Container(
            color: AppColors.accent,
            padding: const EdgeInsets.all(13),
            alignment: Alignment.center,
            child: Text('أضِف الحدث', style: AppText.h(14, color: AppColors.white)),
          ),
        ),
        const SizedBox(height: 20),
        Text('الأحداث المسجّلة', style: AppText.h(15)),
        const SizedBox(height: 6),
        if (s.events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('لسه مفيش أحداث', style: AppText.body(12, color: AppColors.neutral600)),
          ),
        for (final e in s.events)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(e.minute != null ? "${e.minute}'" : '—', style: AppText.h(12, color: AppColors.accent)),
                ),
                Expanded(child: Text(widget.cubit.playerName(e.playerId), style: AppText.h(13))),
                Text(PointsEngine.eventLabel(e.type), style: AppText.body(11, color: AppColors.neutral700)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => widget.cubit.removeEvent(e.id),
                  child: const Icon(Icons.close, size: 18, color: AppColors.danger),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
