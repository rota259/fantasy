import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../cubit/manager_players_cubit.dart';

const _positions = [('GK', 'حارس'), ('DEF', 'دفاع'), ('MID', 'وسط'), ('FWD', 'مهاجم')];

/// (مدير) شيت تعديل اسم/نادي/مركز لاعب.
Future<void> showPlayerEditSheet(BuildContext context, ManagerPlayersCubit cubit, Player p) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    builder: (_) => _EditSheet(cubit: cubit, player: p),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.cubit, required this.player});
  final ManagerPlayersCubit cubit;
  final Player player;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _name = TextEditingController(text: widget.player.name);
  late final _team = TextEditingController(text: widget.player.team);
  late String _pos = widget.player.position;

  @override
  void dispose() {
    _name.dispose();
    _team.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final team = _team.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (name.isEmpty || team.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('اكتب الاسم والنادي')));
      return;
    }
    final err = await widget.cubit.update(widget.player.id, name: name, team: team, position: _pos);
    navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'اتعدّل اللاعب ✓')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('تعديل اللاعب', style: AppText.h(16)),
            const SizedBox(height: 12),
            _field(_name, 'اسم اللاعب'),
            const SizedBox(height: 10),
            _field(_team, 'النادي'),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in _positions)
                GestureDetector(
                  onTap: () => setState(() => _pos = p.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _pos == p.$1 ? AppColors.accent : null,
                      border: Border.all(color: _pos == p.$1 ? AppColors.accent : AppColors.black, width: 2),
                    ),
                    child: Text(p.$2, style: AppText.h(12, color: _pos == p.$1 ? AppColors.white : AppColors.ink)),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _save,
              child: Container(
                color: AppColors.accent,
                padding: const EdgeInsets.all(13),
                alignment: Alignment.center,
                child: Text('احفظ التعديل', style: AppText.h(14, color: AppColors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) => Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
        child: TextField(
          controller: c,
          style: AppText.h(14),
          decoration: InputDecoration(
            isDense: true, border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            hintText: hint,
          ),
        ),
      );
}
