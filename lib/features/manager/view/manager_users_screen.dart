import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/data/models/app_user.dart';
import '../../zones/data/zone.dart';
import '../../zones/data/zones_repository.dart';
import '../../zones/widgets/zone_picker_sheet.dart';
import '../data/admin_repository.dart';
import '../widgets/confirm_dialog.dart';
import '../../../core/widgets/motion.dart';

/// (أدمن) المستخدمين: خلّي يوزر مدير منطقة أو رجّعه، وانقل حد لمنطقة تانية.
/// الأدمن الجديد بيتضاف من Supabase بس (مش من هنا).
class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  late final AdminRepository _repo = context.read<AdminRepository>();
  late Future<(List<AppUser>, Map<int, Zone>, AdminCounts)> _future = _load();
  String _q = '';

  /// البحث في السيرفر (أول ١٠٠ نتيجة) — مش بنحمّل كل اليوزرز.
  Future<(List<AppUser>, Map<int, Zone>, AdminCounts)> _load() async {
    final (users, zones, counts) = await (
      _repo.fetchUsers(query: _q.isEmpty ? null : _q),
      context.read<ZonesRepository>().fetchAll(),
      _repo.counts(),
    ).wait;
    return (users, {for (final z in zones) z.id: z}, counts);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
      setState(() {
        _future = _load();
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  Future<void> _toggle(AppUser u) async {
    final toManager = !u.isOrganizer;
    final ok = await confirmDialog(
      context,
      toManager ? 'خلّيه مدير منطقة؟' : 'رجّعه يوزر عادي؟',
      toManager
          ? '«${u.name}» هيدير فرقه وماتشاته في منطقته بس. حسابه هيبقى حساب شغل: مش هيلعب فانتازي '
                'ولا يصوّت، وهيخرج من الدوريات.'
          : '«${u.name}» مش هيقدر يعمل ماتشات أو فرق تاني.',
    );
    if (!ok || !mounted) return;
    await _run(() => _repo.setRole(u.id, toManager ? 'organizer' : 'user'), 'اتغيّر الدور ✓');
  }

  Future<void> _ban(AppUser u) async {
    final ban = u.isActive;
    final ok = await confirmDialog(
      context,
      ban ? 'حظر «${u.name}»؟' : 'فك حظر «${u.name}»؟',
      ban
          ? 'هيقدر يتفرّج بس: مش هيعمل تشكيلة ولا يصوّت ولا يعلّق ولا يحجز، ومش هيظهر في الترتيب.'
          : 'هيرجع يستخدم الأبلكيشن عادي.',
    );
    if (!ok || !mounted) return;
    await _run(() => _repo.setActive(u.id, !ban), ban ? 'اتحظر ✓' : 'اتفك الحظر ✓');
  }

  Future<void> _move(AppUser u) async {
    final z = await showZonePicker(context);
    if (z == null || !mounted) return;
    await _run(() => _repo.setZone(u.id, z.id), '«${u.name}» بقى في ${z.label} ✓');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'المستخدمين', subtitle: 'ADMIN · USERS', onBack: () => Navigator.pop(context)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() {
                _q = v.trim();
                _future = _load();
              }),
              decoration: const InputDecoration(
                hintText: 'دوّر بالاسم أو الإيميل أو الموبايل ودوس بحث',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<(List<AppUser>, Map<int, Zone>, AdminCounts)>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                  );
                }
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                final (users, zones, counts) = snap.data!;
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${counts.users} يوزر · ${counts.admins} أدمن · ${counts.managers} مدير منطقة'
                        '${_q.isEmpty ? ' · الأعلى نقط' : ' · نتايج «$_q»'}',
                        style: AppText.h(14),
                      ),
                    ),
                    for (final u in users) _row(u, zones[u.zoneId]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AppUser u, Zone? zone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.isActive ? u.name : '${u.name} · محظور 🚫', style: AppText.h(14)),
                Text(
                  '${zone?.label ?? 'من غير منطقة'} · ${u.phone ?? u.email}',
                  style: AppText.body(10, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          if (u.isManager || u.isOrganizer)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: u.isManager ? AppColors.accent : AppColors.info,
                borderRadius: AppRadius.sm,
              ),
              child: Text(u.isManager ? 'أدمن' : 'مدير', style: AppText.h(10, color: AppColors.white)),
            ),
          // الأدمن مبيتغيّرش من التطبيق
          if (!u.isManager) ...[
            _btn(u.isActive ? 'حظر' : 'فك', () => _ban(u)),
            if (u.isOrganizer) _btn('انقله', () => _move(u)),
            _btn(u.isOrganizer ? 'رجّعه يوزر' : 'خلّيه مدير', () => _toggle(u)),
          ],
        ],
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) => Pressable(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: Text(label, style: AppText.h(11)),
    ),
  );
}
