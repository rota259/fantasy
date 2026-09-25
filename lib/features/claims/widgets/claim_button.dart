import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../players/data/models/player.dart';
import '../data/claims_repository.dart';
import '../data/models/player_claim.dart';
import '../view/player_fan_screen.dart';

/// في صفحة اللاعب: "ده أنا 🙋" (طلب توثيق) · طلبك مستني · موثّق ✓ · أنا كلاعب ›
class ClaimButton extends StatefulWidget {
  const ClaimButton({super.key, required this.player, required this.userId});

  final Player player;
  final String userId;

  @override
  State<ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<ClaimButton> {
  late final ClaimsRepository _repo = context.read<ClaimsRepository>();
  late Future<(PlayerClaim?, Player?)> _future = _load();

  Future<(PlayerClaim?, Player?)> _load() => (_repo.mine(widget.userId), _repo.linkedPlayer(widget.userId)).wait;

  Future<void> _request() async {
    final note = await _askNote();
    if (note == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.request(widget.player.id, widget.userId, note);
      messenger.showSnackBar(const SnackBar(content: Text('اتبعت الطلب للمدير — هيوصلك إشعار لما يتأكد ✓')));
      setState(() {
        _future = _load();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e)), backgroundColor: AppColors.danger));
    }
  }

  Future<String?> _askNote() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(),
        title: Text('انت ${widget.player.name}؟', style: AppText.h(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المدير هيتأكد منك (ممكن يكلّمك). بعدها البروفايل ياخد ✓ وتشوف مين اختارك.',
              style: AppText.body(12, color: AppColors.neutral700),
            ),
            TextField(
              controller: ctrl,
              maxLength: 300,
              decoration: const InputDecoration(hintText: 'ملاحظة للمدير (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('ابعت الطلب')),
        ],
      ),
    ).whenComplete(() => WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(PlayerClaim?, Player?)>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final (claim, linked) = snap.data!;
        final p = widget.player;
        if (linked?.id == p.id) {
          return _bar('أنا كلاعب — شوف مين اختارك ›', AppColors.info, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerFanScreen(player: p)));
          });
        }
        if (p.isVerified) return _bar('✓ لاعب موثّق', AppColors.info, null);
        if (linked != null) return const SizedBox.shrink(); // موثّق على لاعب تاني
        if (claim != null && claim.isPending) {
          return _bar(
            claim.playerId == p.id ? '⏳ طلبك مستني موافقة المدير' : 'عندك طلب توثيق تاني مستني',
            AppColors.neutral600,
            null,
          );
        }
        return _bar('انت اللاعب ده؟ ده أنا 🙋', AppColors.black, _request);
      },
    );
  }

  Widget _bar(String t, Color c, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      color: c,
      alignment: Alignment.center,
      child: Text(t, style: AppText.h(13, color: AppColors.white)),
    ),
  );
}
