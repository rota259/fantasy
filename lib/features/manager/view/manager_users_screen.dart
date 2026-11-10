import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/selection_bar.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/data/models/app_user.dart';
import '../../points/view/live_round_screen.dart';
import '../../zones/data/zone.dart';
import '../../zones/data/zones_repository.dart';
import '../../zones/widgets/zone_picker_sheet.dart';
import '../data/admin_repository.dart';
import '../widgets/confirm_dialog.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

part 'manager_users_screen_sections.dart';
part 'manager_users_screen_sections2.dart';

/// (أدمن) المستخدمين: خلّي يوزر مدير منطقة أو رجّعه، وانقل حد لمنطقة تانية، وشوف تشكيلته.
/// تحديد كذا حد (أو الكل) → رجّع المديرين يوزرز أو امسح الحسابات خالص.
/// الأدمن الجديد بيتضاف من Supabase بس (مش من هنا)، والأدمنز مبيتمسحوش.
class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key, this.role});

  /// فلتر البداية (من لوحة الأدمن): user · organizer · null = الكل.
  final String? role;

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  late final AdminRepository _repo = context.read<AdminRepository>();
  late Future<(List<AppUser>, Map<int, Zone>, AdminCounts)> _future = _load();
  String _q = '';
  late String? _role = widget.role; // null = الكل · user · organizer
  Set<String>? _sel; // null = مش في وضع التحديد

  /// البحث في السيرفر (أول ١٠٠ نتيجة) — مش بنحمّل كل اليوزرز.
  Future<(List<AppUser>, Map<int, Zone>, AdminCounts)> _load() async {
    final (users, zones, counts) = await (
      _repo.fetchUsers(query: _q.isEmpty ? null : _q, role: _role),
      context.read<ZonesRepository>().fetchAll(),
      _repo.counts(),
    ).wait;
    return (users, {for (final z in zones) z.id: z}, counts);
  }

  Future<void> _move(AppUser u) async {
    final z = await showZonePicker(context);
    if (z == null || !mounted) return;
    await _run(() => _repo.setZone(u.id, z.id), '«${u.name}» بقى في ${z.label} ✓');
  }

  Future<void> _supervise(AppUser u) async {
    final on = await showDialog<bool>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('مشرف منطقة — ${u.name}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('خلّيه مشرف منطقته (يعتمد ويلغي)'),
          ),
          SimpleDialogOption(onPressed: () => Navigator.pop(c, false), child: const Text('شيل الإشراف')),
        ],
      ),
    );
    if (on == null || !mounted) return;
    if (on && u.zoneId == null) return;
    await _run(
      () => _repo.setSupervisor(u.id, on ? u.zoneId : null),
      on ? '«${u.name}» بقى مشرف ✓' : 'اتشال الإشراف ✓',
    );
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
