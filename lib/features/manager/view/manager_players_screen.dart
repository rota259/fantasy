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

part 'manager_players_screen_sections.dart';
part 'manager_players_screen_sections2.dart';
part 'manager_players_screen_sections3.dart';

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
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

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

  @override
  Widget build(BuildContext context) => _buildBody(context);
}
