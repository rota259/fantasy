part of 'manager_add_match_screen.dart';

extension _ManagerAddMatchScreenStateSections1 on _ManagerAddMatchScreenState {
  Future<void> _pickKickoff() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(Duration(days: _isAdmin ? 14 : 1)), // الأدمن يضيف ماتش اتلعب في الجولة
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    _update(() => _kickoff = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_teamA.text.trim().isEmpty || _teamB.text.trim().isEmpty || _kickoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الفريقين واختر المعاد')));
      return;
    }
    if (!_isAdmin && !_isEdit && _kickoff!.isBefore(DateTime.now().add(const Duration(hours: 2)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الماتش لازم يتعمل قبل ميعاده بساعتين على الأقل — عشان الناس تلحق تختار لاعيبته')),
      );
      return;
    }
    if (WeekWindow.inGap(_kickoff!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('مفيش ماتشات السبت من ٨ الصبح لـ ٤ العصر (بين الجولتين)')));
      return;
    }
    _update(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final teamA = _teamA.text.trim();
    final teamB = _teamB.text.trim();
    final week = int.tryParse(_week.text) ?? 1;
    try {
      if (_isEdit) {
        await widget.matchesRepo.updateMatch(
          widget.editing!.id,
          teams: [teamA, teamB],
          dateTime: _kickoff!,
          week: week,
          durationMin: _duration,
        );
      } else {
        await widget.matchesRepo.addMatch(
          teams: [teamA, teamB],
          dateTime: _kickoff!,
          week: week,
          durationMin: _duration,
        );
      }
      navigator.pop(true);
    } catch (e) {
      _update(() => _saving = false);
      final fallback = _isEdit ? 'تعذّر تعديل الماتش' : 'تعذّر إنشاء الماتش';
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: fallback))));
    }
  }

  /// المدير بيختار من فرقه، والأدمن بيكتب أي اسم.
  Widget _team(TextEditingController c, String hint, {bool opponent = false}) {
    final user = context.read<AuthCubit>().state.user;
    if (user == null || !user.isOrganizer) return _field(c, hint);
    return Pressable(
      onTap: () async {
        final name = await showTeamPicker(context, user.id, opponents: opponent, zoneId: user.zoneId);
        if (name != null) _update(() => c.text = name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                c.text.isEmpty
                    ? opponent
                          ? '$hint (فريقك أو فريق كابتن تاني)'
                          : '$hint (من فرقك)'
                    : c.text,
                style: AppText.h(14, color: c.text.isEmpty ? AppColors.neutral600 : AppColors.ink),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
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
}
