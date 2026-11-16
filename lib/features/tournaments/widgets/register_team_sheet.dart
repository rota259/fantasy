import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../teams/data/team.dart';
import '../../teams/data/teams_repository.dart';
import '../cubit/tournament_cubit.dart';

/// كابتن فريق بيسجّل فريقه: الاسم (فريقه لو عنده) + موبايل للتواصل + ملاحظة — المنظّم يوافق.
/// بعد الموافقة الفريق بيبقى باسم الكابتن في «فريقي» وهو اللي يضيف لاعيبته.
Future<void> showRegisterTeamSheet(BuildContext context, TournamentCubit cubit) async {
  final u = context.read<AuthCubit>().state.user;
  final repo = context.read<TeamsRepository>();
  final mine = u == null ? const <Team>[] : await repo.mine(u.id).catchError((_) => const <Team>[]);
  if (!context.mounted) return;
  final name = TextEditingController(text: mine.isEmpty ? '' : mine.first.name);
  final phone = TextEditingController();
  final note = TextEditingController();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    builder: (c) => Padding(
      padding: EdgeInsets.fromLTRB(18, 4, 18, MediaQuery.viewInsetsOf(c).bottom + 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('سجّل فريقك', style: AppText.h(18)),
          const SizedBox(height: 4),
          Text(
            'بعد ما المنظّم يوافق، الفريق بيبقى باسمك في «فريقي» — ضيف لاعيبته من هناك، '
            'وابعت لينك الأبلكيشن لجروب الفريق عشان اللاعيبة يوثّقوا حساباتهم.',
            style: AppText.body(12, color: AppColors.neutral700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: const InputDecoration(hintText: 'اسم الفريق'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'موبايل الكابتن'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: note,
            decoration: const InputDecoration(hintText: 'ملاحظة (اختياري)'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(c);
              final nav = Navigator.of(c);
              if (name.text.trim().length < 2 || phone.text.trim().length < 8) {
                messenger.showSnackBar(const SnackBar(content: Text('اكتب اسم الفريق والموبايل')));
                return;
              }
              final err = await cubit.requestTeam(name.text.trim(), phone.text.trim(), note.text.trim());
              messenger.showSnackBar(SnackBar(content: Text(err ?? 'الطلب اتبعت للمنظّم ✓')));
              if (err == null) nav.pop();
            },
            child: const Text('ابعت الطلب'),
          ),
        ],
      ),
    ),
  );
}
