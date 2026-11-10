part of 'manager_add_match_screen.dart';

extension _ManagerAddMatchScreenStateSections2 on _ManagerAddMatchScreenState {
  Widget _buildBody(BuildContext context) {
    final k = _kickoff;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: _isEdit ? 'تعديل ماتش' : 'ماتش جديد',
            subtitle: _isEdit ? 'EDIT MATCH' : 'NEW MATCH',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _team(_teamA, 'الفريق الأول'),
                const SizedBox(height: 10),
                _team(_teamB, 'الفريق التاني', opponent: true),
                const SizedBox(height: 10),
                _field(_week, 'رقم الجولة', number: true),
                const SizedBox(height: 12),
                Pressable(
                  onTap: _pickKickoff,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.md,
                      border: Border.all(color: AppColors.line, width: 1.2),
                    ),
                    child: Text(
                      k == null ? 'اختر معاد الماتش' : 'المعاد: ${arabicWeekday(k)} ${arabicTime(k)}',
                      style: AppText.h(13, color: k == null ? AppColors.neutral600 : AppColors.ink),
                    ),
                  ),
                ),
                if (k != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'لاعيبته بيتقفلوا في تشكيلات الناس ${arabicTime(k.subtract(const Duration(hours: 1)))} (قبل الماتش بساعة)'
                    ' — وأهل منطقتك بيوصلهم إشعار أول ما تحفظ.',
                    style: AppText.body(11, color: AppColors.accent700),
                  ),
                ],
                const SizedBox(height: 14),
                Text('مدة الماتش', style: AppText.kicker()),
                const SizedBox(height: 6),
                DurationChips(value: _duration, onChanged: (d) => _update(() => _duration = d)),
                const SizedBox(height: 6),
                Text(
                  k == null
                      ? 'الماتش بيتقفل لوحده لما مدته تخلص — وتقدر تزوّد وقت وهو شغال.'
                      : 'هيتقفل لوحده ${arabicTime(k.add(Duration(minutes: _duration)))} — وتقدر تزوّد وقت وهو شغال.',
                  style: AppText.body(11, color: AppColors.neutral700),
                ),
                const SizedBox(height: 16),
                Pressable(
                  onTap: _saving ? null : _save,
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                    padding: const EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.white),
                          )
                        : Text('احفظ الماتش', style: AppText.h(14, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
