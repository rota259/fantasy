import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/pentagon_avatar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/data/models/app_user.dart';
import '../../squad/data/profile_repository.dart';

/// ترويسة الحساب (سوداء) — صورتك جوه خماسي (دوس تغيّرها) + الاسم.
class AccountHeader extends StatefulWidget {
  const AccountHeader({super.key, this.user});
  final AppUser? user;

  @override
  State<AccountHeader> createState() => _AccountHeaderState();
}

class _AccountHeaderState extends State<AccountHeader> {
  bool _uploading = false;

  Future<void> _changePhoto(AppUser u) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<ProfileRepository>();
    final auth = context.read<AuthCubit>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 800);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      await repo.uploadAvatar(u.id, await file.readAsBytes(), ext);
      await auth.refresh();
      messenger.showSnackBar(const SnackBar(content: Text('اتغيّرت صورتك ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e, fallback: 'الصورة مترفعتش — جرّب تاني'))));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final name = (u != null && u.name.isNotEmpty) ? u.name : 'ضيف';
    final handle = u == null
        ? ''
        : '@${u.email.split('@').first}${u.createdAt != null ? ' · عضو من ${u.createdAt!.year}' : ''}';
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Pressable(
            onTap: (u == null || _uploading) ? null : () => _changePhoto(u),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                PentagonAvatar(initials: u?.initials ?? '؟', photoUrl: u?.photoUrl, size: 68),
                Positioned(
                  bottom: -2,
                  left: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: AppRadius.md),
                    child: _uploading
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : Icon(Icons.photo_camera_outlined, size: 13, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.h(22, color: AppColors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// أرقامي: إجمالي النقاط (الضغط → تفاصيل كل جولة وموسم) + الترتيب العام + أحسن جولة.
class AccountStats extends StatelessWidget {
  const AccountStats({super.key, this.user, this.rank = 0, this.bestMatch = 0, this.onPointsTap});
  final AppUser? user;
  final int rank;
  final int bestMatch;
  final VoidCallback? onPointsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Row(
        children: [
          _stat(
            user != null ? '${user!.totalPoints}' : '—',
            onPointsTap == null ? 'إجمالي النقاط' : 'إجمالي النقاط · التفاصيل ›',
            border: true,
            color: onPointsTap == null ? null : AppColors.accent,
            onTap: onPointsTap,
          ),
          _stat(rank > 0 ? '$rank' : '—', 'الترتيب العام', border: true),
          _stat(bestMatch > 0 ? '$bestMatch' : '—', 'أحسن جولة', color: AppColors.accent),
        ],
      ),
    );
  }

  Widget _stat(String v, String k, {bool border = false, Color? color, VoidCallback? onTap}) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: border ? Border(left: BorderSide(color: AppColors.divider)) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v, style: AppText.h(22, color: color ?? AppColors.ink)),
              Text(k, style: AppText.body(9, color: AppColors.neutral700)),
            ],
          ),
        ),
      ),
    );
  }
}
