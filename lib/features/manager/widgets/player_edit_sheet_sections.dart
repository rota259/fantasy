part of 'player_edit_sheet.dart';

extension _EditSheetStateSections1 on _EditSheetState {
  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (f == null) return;
    _update(() => _uploading = true);
    final ext = f.name.contains('.') ? f.name.split('.').last : 'jpg';
    final err = await widget.cubit.setPhoto(widget.player.id, await f.readAsBytes(), ext);
    if (!mounted) return;
    _update(() => _uploading = false);
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
    } else {
      final fresh = widget.cubit.state.players.where((p) => p.id == widget.player.id).firstOrNull;
      _update(() => _photo = fresh?.imageUrl);
    }
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
