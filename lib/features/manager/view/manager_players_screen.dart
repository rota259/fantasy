import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/selection_bar.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/models/player.dart';
import '../../players/data/players_repository.dart';
import '../cubit/manager_players_cubit.dart';
import '../widgets/player_edit_sheet.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

/// في الخماسي مفيش غير حارس ولاعب (اللاعب بيتخزّن FWD).
const _positions = [('FWD', 'لاعب'), ('GK', 'حارس')];

/// إدارة اللاعيبة: الأدمن (إضافة · تعديل · حذف أي لاعب) أو مدير المنطقة ([teams] = فرقه: حذف لاعيبته
/// اللي لسه ملعبوش). الحذف واحد واحد، أو تحديد كذا لاعب، أو الكل.
class ManagerPlayersScreen extends StatelessWidget {
  const ManagerPlayersScreen({super.key, required this.playersRepo, this.teams});

  final PlayersRepository playersRepo;
  final List<String>? teams;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerPlayersCubit(playersRepo, teams: teams)..load(),
      child: _View(organizer: teams != null),
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this.organizer});
  final bool organizer;
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _name = TextEditingController();
  final _team = TextEditingController();
  String _pos = 'FWD';
  Set<String>? _sel; // null = مش في وضع التحديد

  @override
  void dispose() {
    _name.dispose();
    _team.dispose();
    super.dispose();
  }

  void _add(ManagerPlayersCubit cubit) {
    if (_name.text.trim().isEmpty || _team.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الاسم والنادي')));
      return;
    }
    cubit.add(name: _name.text.trim(), team: _team.text.trim(), position: _pos);
    _name.clear();
    _team.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: widget.organizer ? 'لاعيبتي' : 'إدارة اللاعيبة',
            subtitle: widget.organizer ? 'MY PLAYERS' : 'ADMIN · PLAYERS',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: BlocBuilder<ManagerPlayersCubit, ManagerPlayersState>(
              builder: (context, s) {
                final cubit = context.read<ManagerPlayersCubit>();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (!widget.organizer) ...[
                      _field(_name, 'اسم اللاعب'),
                      const SizedBox(height: 10),
                      _field(_team, 'النادي'),
                      const SizedBox(height: 10),
                      _positionChips(),
                      const SizedBox(height: 12),
                      Pressable(
                        onTap: () => _add(cubit),
                        child: Container(
                          decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                          padding: const EdgeInsets.all(13),
                          alignment: Alignment.center,
                          child: Text('أضِف اللاعب', style: AppText.h(14, color: AppColors.white)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'بتضيف لاعيبة من تشكيلة الماتش. الحذف للاعيبة اللي لسه ملعبوش بس — اللي لعب كلّم الإدارة.',
                          style: AppText.body(11, color: AppColors.neutral700),
                        ),
                      ),
                    SelectionBar(
                      title: 'اللاعيبة (${s.players.length})',
                      selecting: _sel != null,
                      selected: _sel?.length ?? 0,
                      total: s.players.length,
                      onStart: () => setState(() => _sel = {}),
                      onCancel: () => setState(() => _sel = null),
                      onSelectAll: () => setState(() {
                        _sel = _sel!.length == s.players.length ? {} : {for (final p in s.players) p.id};
                      }),
                      actions: [
                        (
                          label: '🗑 احذف المحدّد (${_sel?.length ?? 0})',
                          color: AppColors.danger,
                          onTap: (_sel?.isEmpty ?? true) ? null : () => _bulkDelete(cubit, _sel!.toList(), all: false),
                        ),
                        (
                          label: '🗑 احذف الكل (${s.players.length})',
                          color: AppColors.black,
                          onTap: () => _bulkDelete(cubit, [for (final p in s.players) p.id], all: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (s.isLoading) Padding(padding: EdgeInsets.all(20), child: const SkeletonList()),
                    if (!s.isLoading && s.players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'لسه مضفتش لاعيبة. ضيف أول لاعب من فوق.',
                          style: AppText.body(12, color: AppColors.neutral600),
                        ),
                      ),
                    // كل فريق لوحده وتحته لاعيبته (الحارس الأول)
                    for (final team in _byTeam(s.players).entries) ...[
                      _teamHeader(team.key, team.value),
                      for (final p in team.value)
                        if (_sel != null)
                          CheckboxListTile(
                            dense: true,
                            contentPadding: const EdgeInsetsDirectional.only(start: 12),
                            value: _sel!.contains(p.id),
                            onChanged: (on) => setState(() => on == true ? _sel!.add(p.id) : _sel!.remove(p.id)),
                            title: Text(p.name, style: AppText.h(13)),
                            subtitle: Text(p.positionAr, style: AppText.body(10)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 12),
                            child: _playerRow(
                              '${p.name}${p.position == 'GK' ? ' 🧤' : ''}',
                              p.positionAr,
                              onEdit: widget.organizer ? null : () => showPlayerEditSheet(context, cubit, p),
                              onDelete: () => _confirmDelete(cubit, p.id, p.name),
                            ),
                          ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// اللاعيبة متقسّمين بالفريق (الفرق بالأبجدية، والحارس أول واحد في فريقه).
  static Map<String, List<Player>> _byTeam(List<Player> players) {
    final map = <String, List<Player>>{};
    for (final p in players) {
      map.putIfAbsent(p.team.trim().isEmpty ? 'من غير فريق' : p.team, () => []).add(p);
    }
    for (final l in map.values) {
      l.sort((a, b) {
        final g = (a.position == 'GK' ? 0 : 1).compareTo(b.position == 'GK' ? 0 : 1);
        return g != 0 ? g : a.name.compareTo(b.name);
      });
    }
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  /// عنوان الفريق: اسمه + عدد لاعيبته — ووقت التحديد بيحدّد/يلغي الفريق كله.
  Widget _teamHeader(String team, List<Player> players) {
    final sel = _sel;
    final all = sel != null && players.every((p) => sel.contains(p.id));
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(team, style: AppText.h(14, color: AppColors.accent700)),
          ),
          Text('${players.length} لاعب', style: AppText.body(11, color: AppColors.accent700)),
          if (sel != null)
            Checkbox(
              value: all,
              visualDensity: VisualDensity.compact,
              onChanged: (on) => setState(() {
                for (final p in players) {
                  on == true ? sel.add(p.id) : sel.remove(p.id);
                }
              }),
            ),
        ],
      ),
    );
  }

  /// حذف المحدّدين أو الكل (الكل لازم يكتب "احذف").
  Future<void> _bulkDelete(ManagerPlayersCubit cubit, List<String> ids, {required bool all}) async {
    final ok = await confirmBulk(
      context,
      all ? 'حذف كل اللاعيبة' : 'حذف ${ids.length} لاعب',
      all
          ? 'هتحذف ${ids.length} لاعب، ومعاهم أحداثهم ونقطهم في تشكيلات الناس. مفيش رجوع.'
          : 'متأكد؟ أحداثهم ونقطهم في تشكيلات الناس هتتمسح معاهم.',
      typeToConfirm: all ? 'احذف' : null,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final r = await cubit.removeMany(ids);
    if (!mounted) return;
    setState(() => _sel = null);
    final skipped = r.skipped > 0 ? ' · ${r.skipped} مااتحذفوش (لعبوا واتسجّل لهم أحداث)' : '';
    messenger.showSnackBar(SnackBar(content: Text(r.error ?? 'اتحذف ${r.deleted} ✓$skipped')));
  }

  Future<void> _confirmDelete(ManagerPlayersCubit cubit, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text('حذف اللاعب', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «$name»؟', style: AppText.body(13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: AppText.h(13, color: AppColors.neutral700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = await cubit.remove(id);
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'اتحذف «$name» ✓'), duration: const Duration(milliseconds: 2200)),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.line, width: 1.2),
      ),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: AppText.h(14),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          hintText: hint,
        ),
      ),
    );
  }

  Widget _positionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in _positions)
          Pressable(
            onTap: () => setState(() => _pos = p.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: AppRadius.md,
                color: _pos == p.$1 ? AppColors.accent : null,
                border: Border.all(color: _pos == p.$1 ? AppColors.accent : AppColors.black, width: 2),
              ),
              child: Text(p.$2, style: AppText.h(12, color: _pos == p.$1 ? AppColors.white : AppColors.ink)),
            ),
          ),
      ],
    );
  }

  Widget _playerRow(String name, String meta, {required VoidCallback? onEdit, required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: AppDecor.softDivider,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppText.h(13)),
                Text(meta, style: AppText.body(10, color: AppColors.neutral700)),
              ],
            ),
          ),
          if (onEdit != null)
            Pressable(
              onTap: onEdit,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.edit_outlined, size: 18, color: AppColors.neutral700),
              ),
            ),
          Pressable(
            onTap: onDelete,
            child: Icon(Icons.close, size: 18, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
