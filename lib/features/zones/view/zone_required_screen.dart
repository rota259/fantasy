import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/widgets/login_header.dart';
import '../data/zone.dart';
import '../data/zones_repository.dart';
import '../widgets/zone_field.dart';
import '../../../core/widgets/motion.dart';

/// الحسابات القديمة (من غير منطقة) لازم تختار منطقتها قبل ما تدخل.
class ZoneRequiredScreen extends StatefulWidget {
  const ZoneRequiredScreen({super.key});

  @override
  State<ZoneRequiredScreen> createState() => _ZoneRequiredScreenState();
}

class _ZoneRequiredScreenState extends State<ZoneRequiredScreen> {
  Zone? _zone;
  bool _busy = false;

  Future<void> _save() async {
    final z = _zone;
    if (z == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthCubit>();
    setState(() => _busy = true);
    try {
      await context.read<ZonesRepository>().setMine(z.id);
      await auth.refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const LoginHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(26),
              children: [
                Text('انت منين؟ 📍', style: AppText.h(22)),
                const SizedBox(height: 4),
                Text(
                  'الأبلكيشن بقى بالمناطق: كل منطقة ليها ماتشاتها ونجم وتشكيلة جولتها.',
                  style: AppText.body(13, color: AppColors.neutral700),
                ),
                const SizedBox(height: 20),
                ZoneField(value: _zone, onChanged: (z) => setState(() => _zone = z)),
                const SizedBox(height: 20),
                Pressable(
                  onTap: (_zone == null || _busy) ? null : _save,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (_zone == null || _busy) ? AppColors.neutral500 : AppColors.accent,
                      borderRadius: AppRadius.md,
                    ),
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.center,
                    child: Text('يلا', style: AppText.h(15, color: AppColors.white)),
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
