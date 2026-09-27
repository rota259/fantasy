import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../players/data/models/player.dart';
import '../cubit/manager_players_cubit.dart';
import '../../../core/widgets/motion.dart';

const _positions = [('GK', 'حارس'), ('DEF', 'دفاع'), ('MID', 'وسط'), ('FWD', 'مهاجم')];

/// (مدير) شيت تعديل صورة/اسم/نادي/مركز لاعب.
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
  late String? _photo = widget.player.imageUrl;
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (f == null) return;
    setState(() => _uploading = true);
    final ext = f.name.contains('.') ? f.name.split('.').last : 'jpg';
    final err = await widget.cubit.setPhoto(widget.player.id, await f.readAsBytes(), ext);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      final fresh = widget.cubit.state.players.where((p) => p.id == widget.player.id).firstOrNull;
      setState(() => _photo = fresh?.imageUrl);
    }
  }

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Pressable(
                    onTap: _uploading ? null : _pickPhoto,
                    child: PentagonAvatar(initials: widget.player.initials, photoUrl: _photo, size: 56),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploading ? 'بترفع الصورة…' : 'تعديل اللاعب — دوس على الصورة تغيّرها',
                      style: AppText.h(14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_name, 'اسم اللاعب'),
              const SizedBox(height: 10),
              _field(_team, 'النادي'),
              const SizedBox(height: 10),
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
                onTap: _save,
                child: Container(
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                  padding: const EdgeInsets.all(13),
                  alignment: Alignment.center,
                  child: Text('احفظ التعديل', style: AppText.h(14, color: AppColors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint) => Container(
    decoration: BoxDecoration(
      borderRadius: AppRadius.md,
      border: Border.all(color: AppColors.line, width: 1.2),
    ),
    child: TextField(
      controller: c,
      style: AppText.h(14),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        hintText: hint,
      ),
    ),
  );
}
