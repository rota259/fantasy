import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/data/models/app_user.dart';
import '../../squad/data/profile_repository.dart';

part 'account_widgets_extra.dart';

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
                AppAvatar(initials: u?.initials ?? '؟', photoUrl: u?.photoUrl, size: 68),
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
