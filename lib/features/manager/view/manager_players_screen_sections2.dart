part of 'manager_players_screen.dart';

extension _ViewStateSections2 on _ViewState {
  Widget _positionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in _positions)
          Pressable(
            onTap: () => _update(() => _pos = p.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                color: _pos == p.$1 ? AppColors.accent : null,
                border: Border.all(color: _pos == p.$1 ? AppColors.accent : AppColors.line, width: 1.4),
              ),
              child: Text(p.$2, style: AppText.h(12, color: _pos == p.$1 ? AppColors.white : AppColors.ink)),
            ),
          ),
      ],
    );
  }

  Widget _playerRow(String name, String meta, {required VoidCallback? onEdit, required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: AppDecor.softDivider,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h(13)),
                Text(meta, style: AppText.body(10, color: AppColors.neutral700)),
              ],
            ),
          ),
          if (onEdit != null)
            Pressable(
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.edit_outlined, size: 18, color: AppColors.neutral700),
              ),
            ),
          Pressable(
            onTap: onDelete,
            child: Icon(Icons.close, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
