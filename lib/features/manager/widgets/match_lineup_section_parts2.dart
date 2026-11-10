part of 'match_lineup_section.dart';

extension _MatchLineupSectionSections2 on MatchLineupSection {
  Widget _button(String text, {bool filled = false, required VoidCallback onTap}) => Pressable(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(13),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: filled ? AppColors.accent : null,
        border: filled ? null : Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Text(text, style: AppText.h(filled ? 14 : 13, color: filled ? AppColors.white : AppColors.ink)),
    ),
  );
}
