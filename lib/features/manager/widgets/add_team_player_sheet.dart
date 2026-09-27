import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/box_field.dart';
import '../../../core/widgets/motion.dart';

const _positions = [('GK', 'حارس'), ('DEF', 'دفاع'), ('MID', 'وسط'), ('FWD', 'مهاجم')];

/// (مدير) شيت "ضيف لاعب" لفريق في الماتش — بيرجّع (الاسم، المركز).
Future<({String name, String position})?> showAddTeamPlayerSheet(BuildContext context, String team) {
  return showModalBottomSheet<({String name, String position})>(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => _Sheet(team: team),
  );
}

class _Sheet extends StatefulWidget {
  const _Sheet({required this.team});
  final String team;

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _name = TextEditingController();
  String _pos = 'FWD';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ضيف لاعب لـ ${widget.team}', style: AppText.h(15)),
              const SizedBox(height: 12),
              BoxField(controller: _name, hint: 'اسم اللاعب'),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _positions)
                    Pressable(
                      onTap: () => setState(() => _pos = p.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md,
                          color: _pos == p.$1 ? AppColors.accent : null,
                          border: Border.all(color: _pos == p.$1 ? AppColors.accent : AppColors.black, width: 2),
                        ),
                        child: Text(p.$2, style: AppText.h(12, color: _pos == p.$1 ? AppColors.white : AppColors.ink)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Pressable(
                onTap: () {
                  final n = _name.text.trim();
                  if (n.isNotEmpty) Navigator.pop(context, (name: n, position: _pos));
                },
                child: Container(
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text('أضِف', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
