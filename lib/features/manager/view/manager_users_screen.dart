import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/models/app_user.dart';
import '../data/admin_repository.dart';

/// (مدير) كل المستخدمين + ترقية حد لمدير أو شيل الإدارة منه.
class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  late final AdminRepository _repo = context.read<AdminRepository>();
  late Future<(List<AppUser>, String?)> _future = _load();

  Future<(List<AppUser>, String?)> _load() async {
    final me = await context.read<AuthRepository>().currentUser();
    return (await _repo.fetchUsers(), me?.id);
  }

  Future<void> _toggle(AppUser u) async {
    final makeManager = !u.isManager;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(),
        title: Text(makeManager ? 'خلّيه مدير؟' : 'شيل الإدارة؟', style: AppText.h(16)),
        content: Text(
          makeManager ? '«${u.name}» هيقدر يضيف ويحذف لاعيبة وماتشات ويبعت إشعارات.' : '«${u.name}» هيرجع يوزر عادي.',
          style: AppText.body(13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _repo.setRole(u.id, makeManager ? 'manager' : 'user');
      setState(() {
        _future = _load();
      });
      messenger.showSnackBar(const SnackBar(content: Text('اتغيّر الدور ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'المستخدمين', subtitle: 'MANAGER · USERS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<(List<AppUser>, String?)>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('تعذّر التحميل', style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                final (users, myId) = snap.data!;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${users.length} مستخدم · ${users.where((u) => u.isManager).length} مدير',
                        style: AppText.h(14),
                      ),
                    ),
                    for (final u in users) _row(u, isMe: u.id == myId),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppUser u, {required bool isMe}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMe ? '${u.name} (أنت)' : u.name, style: AppText.h(14)),
                Text('${u.email} · ${u.totalPoints} نقطة', style: AppText.body(10, color: AppColors.neutral700)),
              ],
            ),
          ),
          if (u.isManager)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: AppColors.accent,
              child: Text('مدير', style: AppText.h(10, color: AppColors.white)),
            ),
          // المدير مايقدرش يشيل الإدارة من نفسه (عشان ميقفلش على نفسه).
          if (!isMe)
            GestureDetector(
              onTap: () => _toggle(u),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
                child: Text(u.isManager ? 'شيل الإدارة' : 'خلّيه مدير', style: AppText.h(11)),
              ),
            ),
        ],
      ),
    );
  }
}
