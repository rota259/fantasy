part of 'manager_hub_screen.dart';

extension _ManagerHubScreenSections1 on ManagerHubScreen {
  Widget _tile(BuildContext context, IconData icon, String title, String sub, Widget screen) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: AppDecor.tile,
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h(15)),
                  Text(sub, style: AppText.body(11, color: AppColors.neutral700)),
                ],
              ),
            ),
            Text('›', style: AppText.body(18, color: AppColors.neutral600)),
          ],
        ),
      ),
    );
  }
}
