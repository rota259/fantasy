import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/status_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../badges/widgets/badges_preview.dart';
import '../../claims/data/claims_repository.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../points/view/my_points_screen.dart';
import '../../squad/data/profile_repository.dart';
import '../cubit/account_cubit.dart';
import '../widgets/account_menu.dart';
import '../widgets/account_widgets.dart';

/// تبويب حسابي: الصورة + الأرقام + الإنجازات + القايمة.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (c) =>
          AccountCubit(c.read<LeaguesRepository>(), c.read<ProfileRepository>(), c.read<ClaimsRepository>())
            ..load(c.read<AuthCubit>().state.user?.id),
      child: BlocBuilder<AuthCubit, AuthState>(
        buildWhen: (p, c) => p.user != c.user,
        builder: (context, auth) {
          final user = auth.user;
          return Column(
            children: [
              const StatusArea(),
              AccountHeader(user: user),
              Expanded(
                child: BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, s) => ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // حساب المدير حساب شغل: مفيش نقط ولا شارات
                      if (!(user?.isOrganizer ?? false)) ...[
                        AccountStats(
                          user: user,
                          rank: s.rank,
                          bestMatch: s.bestMatch,
                          onPointsTap: user == null
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => MyPointsScreen(userId: user.id)),
                                ),
                        ),
                        if (user != null) BadgesPreview(userId: user.id, userName: user.name),
                      ],
                      Divider(color: AppColors.divider, height: 2, thickness: 2),
                      AccountMenu(user: user, linkedPlayer: s.linkedPlayer),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
