import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../leagues/data/models/league.dart';

const _types = [('public', 'كلاسيك'), ('h2h', 'H2H'), ('private', 'خاص')];

/// (مدير) إنشاء الدوريات وعرض أكواد الدعوة.
class ManagerLeaguesScreen extends StatefulWidget {
  const ManagerLeaguesScreen({super.key});

  @override
  State<ManagerLeaguesScreen> createState() => _ManagerLeaguesScreenState();
}

class _ManagerLeaguesScreenState extends State<ManagerLeaguesScreen> {
  late final LeaguesRepository _repo = context.read<LeaguesRepository>();
  late Future<List<League>> _future = _repo.fetchAll();
  final _name = TextEditingController();
  String _type = 'public';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reload() => setState(() { _future = _repo.fetchAll(); });

  Future<void> _create() async {
    final name = _name.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (name.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('اكتب اسم الدوري')));
      return;
    }
    try {
      final l = await _repo.createLeague(name, _type);
      _name.clear();
      _reload();
      messenger.showSnackBar(SnackBar(content: Text('اتعمل الدوري — الكود: ${l.inviteCode}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('فشل الإنشاء: $e')));
    }
  }

  Future<void> _delete(League l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg,
        shape: const RoundedRectangleBorder(),
        title: Text('حذف الدوري', style: AppText.h(16)),
        content: Text('متأكد إنك عايز تحذف «${l.name}»؟ الأعضاء هيخرجوا منه.', style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('احذف', style: AppText.h(13, color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.deleteLeague(l.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(children: [
        const StatusArea(),
        Masthead(title: 'الدوريات', subtitle: 'MANAGER · LEAGUES', onBack: () => Navigator.pop(context)),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 2)),
              child: TextField(
                controller: _name,
                style: AppText.h(14),
                decoration: const InputDecoration(
                  isDense: true, border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  hintText: 'اسم الدوري',
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              for (final t in _types) ...[
                GestureDetector(
                  onTap: () => setState(() => _type = t.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _type == t.$1 ? AppColors.accent : null,
                      border: Border.all(color: _type == t.$1 ? AppColors.accent : AppColors.black, width: 2),
                    ),
                    child: Text(t.$2, style: AppText.h(12, color: _type == t.$1 ? AppColors.white : AppColors.ink)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _create,
              child: Container(
                color: AppColors.accent,
                padding: const EdgeInsets.all(13),
                alignment: Alignment.center,
                child: Text('+ اعمل دوري', style: AppText.h(14, color: AppColors.white)),
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<League>>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (snap.data!.isEmpty) {
                  return Text('لسه مفيش دوريات', style: AppText.body(12, color: AppColors.neutral600));
                }
                return Column(children: [for (final l in snap.data!) _row(l)]);
              },
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _row(League l) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.name, style: AppText.h(14)),
            Text('${l.typeLabel} · ${l.memberCount} عضو', style: AppText.body(10, color: AppColors.neutral700)),
          ]),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: l.inviteCode));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اتنسخ الكود ✓')));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: AppColors.black,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(l.inviteCode, style: AppText.h(13, color: AppColors.white, spacingEm: 0.1)),
              const SizedBox(width: 6),
              const Icon(Icons.copy, size: 14, color: AppColors.white),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _delete(l),
          child: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
        ),
      ]),
    );
  }
}
