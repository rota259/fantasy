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

/// (أدمن) المستخدمين: خلّي يوزر مدير منطقة أو رجّعه، وانقل حد لمنطقة تانية، وشوف تشكيلته.
/// تحديد كذا حد (أو الكل) → رجّع المديرين يوزرز أو امسح الحسابات خالص.
/// الأدمن الجديد بيتضاف من Supabase بس (مش من هنا)، والأدمنز مبيتمسحوش.
class ManagerUsersScreen extends StatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  State<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends State<ManagerUsersScreen> {
  late final AdminRepository _repo = context.read<AdminRepository>();
  late Future<(List<AppUser>, Map<int, Zone>, AdminCounts)> _future = _load();
  String _q = '';
  String? _role; // null = الكل · user · organizer
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

  /// المحدّدين: رجّع المديرين يوزرز · امسح الحسابات (الكل لازم يكتب "امسح").
  Future<void> _bulk(List<AppUser> users, {required bool delete, bool all = false}) async {
    final ids = [for (final u in users) u.id];
    final organizers = [
      for (final u in users)
        if (u.isOrganizer) u.id,
    ];
    final ok = await confirmBulk(
      context,
      delete ? 'مسح ${ids.length} حساب' : 'رجّع ${organizers.length} مدير يوزرز',
      delete
          ? 'الحسابات دي هتتمسح خالص بكل بياناتها (تشكيلات · نقط · فرق المديرين تفضل من غير صاحب). مفيش رجوع.'
          : 'مش هيقدروا يعملوا ماتشات أو فرق تاني.',
      typeToConfirm: delete && all ? 'امسح' : null,
    );
    if (!ok || !mounted) return;
    await _run(() async {
      final n = delete ? await _repo.deleteUsers(ids) : await _repo.demoteOrganizers(organizers);
      if (mounted) setState(() => _sel = null);
      if (n == 0) throw StateError('ولا حاجة اتغيّرت');
    }, delete ? 'اتمسحت الحسابات ✓' : 'رجعوا يوزرز ✓');
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
                if (!snap.hasData) return const SkeletonList();
                final (all, zones, counts) = snap.data!;
                final users = [
                  for (final u in all)
                    if (!u.isManager) u,
                ]; // الأدمنز مبيتحدّدوش
                final picked = [
                  for (final u in users)
                    if (_sel?.contains(u.id) ?? false) u,
                ];
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        '${counts.users} يوزر · ${counts.admins} أدمن · ${counts.managers} مدير منطقة'
                        '${_q.isEmpty ? ' · الأعلى نقط' : ' · نتايج «$_q»'}',
                        style: AppText.h(14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [_filter('الكل', null), _filter('يوزرز', 'user'), _filter('مديرين', 'organizer')],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: SelectionBar(
                        title: 'القايمة (${users.length})',
                        selecting: _sel != null,
                        selected: picked.length,
                        total: users.length,
                        onStart: () => setState(() => _sel = {}),
                        onCancel: () => setState(() => _sel = null),
                        onSelectAll: () => setState(() {
                          _sel = picked.length == users.length ? {} : {for (final u in users) u.id};
                        }),
                        actions: [
                          (
                            label: 'رجّع المديرين يوزرز (${picked.where((u) => u.isOrganizer).length})',
                            color: AppColors.info,
                            onTap: picked.any((u) => u.isOrganizer) ? () => _bulk(picked, delete: false) : null,
                          ),
                          (
                            label: '🗑 امسح المحدّد (${picked.length})',
                            color: AppColors.danger,
                            onTap: picked.isEmpty ? null : () => _bulk(picked, delete: true),
                          ),
                          (
                            label: '🗑 امسح الكل (${users.length})',
                            color: AppColors.black,
                            onTap: users.isEmpty ? null : () => _bulk(users, delete: true, all: true),
                          ),
                        ],
                      ),
                    ),
                    for (final u in all)
                      if (_sel != null && !u.isManager)
                        CheckboxListTile(
                          dense: true,
                          value: _sel!.contains(u.id),
                          onChanged: (on) => setState(() => on == true ? _sel!.add(u.id) : _sel!.remove(u.id)),
                          title: Text('${u.name}${u.isOrganizer ? ' · مدير' : ''}', style: AppText.h(13)),
                          subtitle: Text(zones[u.zoneId]?.label ?? 'من غير منطقة', style: AppText.body(10)),
                        )
                      else if (_sel == null)
                        _row(u, zones[u.zoneId]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filter(String label, String? role) {
    final on = _role == role;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Pressable(
        onTap: () => setState(() {
          _role = role;
          _sel = null;
          _future = _load();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : null,
            borderRadius: AppRadius.md,
            border: Border.all(color: on ? AppColors.accent : AppColors.line),
          ),
          child: Text(label, style: AppText.h(12, color: on ? AppColors.white : AppColors.ink)),
        ),
      ),
    );
  }

  /// الضغط على يوزر = تشكيلته في الجولة (للفرجة بس).
  Widget _row(AppUser u, Zone? zone) {
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: u.isOrganizer || u.isManager
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveRoundScreen(userId: u.id, ownerName: u.name),
              ),
            ),
      child: Container(
        margin: AppDecor.tileMargin,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: AppDecor.tile,
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
