import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../players/data/players_repository.dart';
import '../cubit/manager_players_cubit.dart';

const _positions = [('GK', 'حارس'), ('DEF', 'دفاع'), ('MID', 'وسط'), ('FWD', 'مهاجم')];

/// شاشة المدير: إضافة/حذف لاعيبة.
class ManagerPlayersScreen extends StatelessWidget {
  const ManagerPlayersScreen({super.key, required this.playersRepo});

  final PlayersRepository playersRepo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ManagerPlayersCubit(playersRepo)..load(),
      child: const _View(),
    );
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
  final _price = TextEditingController();
  String _pos = 'FWD';

  @override
  void dispose() {
    _name.dispose();
    _team.dispose();
    _price.dispose();
    super.dispose();
  }

  void _add(ManagerPlayersCubit cubit) {
    if (_name.text.trim().isEmpty || _team.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب الاسم والنادي')));
      return;
    }
    cubit.add(
      name: _name.text.trim(),
      team: _team.text.trim(),
      position: _pos,
      price: double.tryParse(_price.text) ?? 5.0,
    );
    _name.clear();
    _team.clear();
    _price.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(
            title: 'إدارة اللاعيبة',
            subtitle: 'MANAGER · PLAYERS',
            onBack: () => Navigator.pop(context),
          ),
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
                    const SizedBox(height: 10),
                    _field(_price, 'السعر (مليون)', number: true),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _add(cubit),
                      child: Container(
                        color: AppColors.accent,
                        padding: const EdgeInsets.all(13),
                        alignment: Alignment.center,
                        child: Text('أضِف اللاعب', style: AppText.h(14, color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('اللاعيبة (${s.players.length})', style: AppText.h(15)),
                    const SizedBox(height: 6),
                    if (s.isLoading)
                      const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
                    for (final p in s.players)
                      _playerRow(p.name, '${p.team} · ${p.positionAr} · ${p.price.toStringAsFixed(1)}م',
                          () => cubit.remove(p.id)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool number = false}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
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
          GestureDetector(
            onTap: () => setState(() => _pos = p.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _pos == p.$1 ? AppColors.accent : null,
                border: Border.all(color: _pos == p.$1 ? AppColors.accent : AppColors.black, width: 2),
              ),
              child: Text(p.$2, style: AppText.h(12, color: _pos == p.$1 ? AppColors.white : AppColors.ink)),
            ),
          ),
      ],
    );
  }

  Widget _playerRow(String name, String meta, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppText.h(13)),
            Text(meta, style: AppText.body(10, color: AppColors.neutral700)),
          ]),
        ),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.close, size: 18, color: AppColors.danger)),
      ]),
    );
  }
}
