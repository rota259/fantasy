import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../data/follows_repository.dart';

/// زرار "تابع لايف 🔔" لماتش — بيقلب بين متابع/مش متابع.
/// الحالة الابتدائية جاية من الشاشة (مجموعة المتابعات)، والتغيير بيتبعت للسيرفر.
class FollowButton extends StatefulWidget {
  const FollowButton({super.key, required this.matchId, required this.userId, required this.following, this.onChanged});

  final String matchId;
  final String userId;
  final bool following;
  final ValueChanged<bool>? onChanged;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  late bool _on = widget.following;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant FollowButton old) {
    super.didUpdateWidget(old);
    if (old.following != widget.following) _on = widget.following;
  }

  Future<void> _toggle() async {
    final repo = context.read<FollowsRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      if (_on) {
        await repo.unfollow(widget.matchId, widget.userId);
      } else {
        await repo.follow(widget.matchId, widget.userId);
        messenger.showSnackBar(const SnackBar(content: Text('🔔 هيوصلك إشعار بكل حاجة في الماتش ده')));
      }
      if (!mounted) return;
      setState(() => _on = !_on);
      widget.onChanged?.call(_on);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e)), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _busy ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _on ? AppColors.accent : null,
          border: Border.all(color: _on ? AppColors.accent : AppColors.black, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _on ? Icons.notifications_active : Icons.notifications_none,
              size: 14,
              color: _on ? AppColors.white : AppColors.ink,
            ),
            const SizedBox(width: 4),
            Text(_on ? 'متابع' : 'تابع لايف', style: AppText.h(10, color: _on ? AppColors.white : AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
