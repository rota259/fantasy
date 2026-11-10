part of 'push_check_screen.dart';

extension _PushCheckScreenStateSections2 on _PushCheckScreenState {
  Widget _check(String title, bool ok, {required String fix, (String, Future<void> Function())? action}) => Container(
    margin: AppDecor.tileMargin,
    padding: const EdgeInsets.all(12),
    decoration: AppDecor.tile,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? AppColors.accent : AppColors.danger, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h(13)),
              if (!ok) ...[
                const SizedBox(height: 2),
                Text(fix, style: AppText.body(11, color: AppColors.neutral700, height: 1.5)),
                if (action != null)
                  TextButton(
                    onPressed: _busy ? null : action.$2,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    child: Text(action.$1),
                  ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
