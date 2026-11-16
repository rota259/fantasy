import 'package:flutter/material.dart';

import '../../../core/app_mode.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../integrity/view/admin_organizers_screen.dart';
import '../../integrity/view/admin_review_screen.dart';
import '../../manager/view/manager_claims_screen.dart';
import '../../pitch/view/pending_venues_screen.dart';

/// مشرف المنطقة (الأدمن بيعيّنه): مراجعة ماتشات منطقته · توثيق اللاعيبة · توثيق الملاعب.
class SupervisorRow extends StatelessWidget {
  const SupervisorRow({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: SupabaseService.client.rpc('am_supervisor').catchError((_) => null),
    builder: (context, snap) {
      if (snap.data == null) return const SizedBox.shrink();
      Widget row(IconData icon, String title, Widget screen) => ListTile(
        leading: Icon(icon, color: AppColors.info),
        title: Text(title, style: AppText.h(14, color: AppColors.info)),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      );
      return Column(
        children: [
          row(Icons.shield_moon_outlined, 'مراجعة ماتشات منطقتك (مشرف)', const AdminReviewScreen()),
          row(Icons.badge_outlined, 'توثيق لاعيبة منطقتك', const ManagerClaimsScreen()),
          row(Icons.how_to_reg_outlined, 'طلبات المديرين في منطقتك', const AdminOrganizersScreen()),
          if (kVenueVerify) row(Icons.verified_outlined, 'توثيق ملاعب منطقتك', const PendingVenuesScreen()),
        ],
      );
    },
  );
}
