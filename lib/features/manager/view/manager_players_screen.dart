import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/players_repository.dart';
import '../cubit/manager_players_cubit.dart';
import '../widgets/player_edit_sheet.dart';
import '../../../core/widgets/motion.dart';

const _positions = [('GK', 'حارس'), ('DEF', 'دفاع'), ('MID', 'وسط'), ('FWD', 'مهاجم')];

/// شاشة المدير: إضافة/حذف لاعيبة.
class ManagerPlayersScreen extends StatelessWidget {
  const ManagerPlayersScreen({super.key, required this.playersRepo});

  final PlayersRepository playersRepo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => ManagerPlayersCubit(playersRepo)..load(), child: const _View());
  }
}

class _View extends StatefulWidget {
  const _View();
  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final _name = TextEditingController();
  final _team = TextEditingController();
  String _pos = 'FWD';

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
          Masthead(title: 'إدارة اللاعيبة', subtitle: 'ADMIN · PLAYERS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: BlocBuilder<ManagerPlayersCubit, ManagerPlayersState>(
              builder: (context, s) {
                final cubit = context.read<ManagerPlayersCubit>();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
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
                    Text('اللاعيبة (${s.players.length})', style: AppText.h(15)),
                    const SizedBox(height: 6),
                    if (s.isLoading)
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      ),
                    if (!s.isLoading && s.players.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'لسه مضفتش لاعيبة. ضيف أول لاعب من فوق.',
                          style: AppText.body(12, color: AppColors.neutral600),
                        ),
                      ),
                    for (final p in s.players)
                      _playerRow(
                        p.name,
                        '${p.team} · ${p.positionAr}',
                        onEdit: () => showPlayerEditSheet(context, cubit, p),
                        onDelete: () => _confirmDelete(cubit, p.id, p.name),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
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

  Widget _playerRow(String name, String meta, {required VoidCallback onEdit, required VoidCallback onDelete}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
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
