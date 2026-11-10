import 'package:flutter/material.dart';

import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../integrity/view/admin_review_screen.dart';

/// مشرف المنطقة (الأدمن بيعيّنه): مدخل لمراجعة ماتشات منطقته — اعتماد أو إلغاء.
class SupervisorRow extends StatelessWidget {
  const SupervisorRow({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: SupabaseService.client.rpc('am_supervisor').catchError((_) => null),
    builder: (context, snap) => snap.data == null
        ? const SizedBox.shrink()
        : ListTile(
            leading: Icon(Icons.shield_moon_outlined, color: AppColors.info),
            title: Text('مراجعة ماتشات منطقتك (مشرف)', style: AppText.h(14, color: AppColors.info)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewScreen())),
          ),
  );
}
