import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../manager/view/manager_match_screen.dart';
import '../data/integrity_repository.dart';
import '../data/models/review_case.dart';
import '../widgets/match_sheet_view.dart';
import 'match_review_screen.dart';
import '../../../core/widgets/motion.dart';

/// (أدمن) الحكم في ماتش: الورقة + آراء اللاعيبة + اعتماد / إلغاء / مراجعة من الأول / تعديل الأحداث.
class AdminCaseScreen extends StatefulWidget {
  const AdminCaseScreen({super.key, required this.reviewCase});
  final ReviewCase reviewCase;

  @override
  State<AdminCaseScreen> createState() => _AdminCaseScreenState();
}

class _AdminCaseScreenState extends State<AdminCaseScreen> {
  late Future<MatchSheet> _sheet = loadMatchSheet(context, widget.reviewCase.match);
  bool _busy = false;

  static const _confirm = {
    'approve': ('اعتماد الماتش؟', 'النقط هتتحسب في الإجمالي والترتيب.'),
    'void': ('إلغاء الماتش؟', 'كل الأحداث هتتمسح ونقط الماتش هتروح من الكل. مفيش رجوع.'),
    'reopen': ('مراجعة من الأول؟', 'التأكيدات هتتمسح واللاعيبة هيوصلهم طلب تأكيد تاني (١٢ ساعة).'),
  };

  Future<void> _act(String action) async {
    final (title, body) = _confirm[action]!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: Text(title, style: AppText.h(16)),
        content: Text(body, style: AppText.body(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await context.read<IntegrityRepository>().resolve(widget.reviewCase.match.id, action);
      messenger.showSnackBar(const SnackBar(content: Text('اتنفّذ ✓')));
      nav.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editEvents() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManagerMatchScreen.of(context, widget.reviewCase.match)),
    );
    if (mounted) {
      setState(() {
        _sheet = loadMatchSheet(context, widget.reviewCase.match);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.reviewCase;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'الحكم', subtitle: 'مدير: ${c.organizerName}', onBack: () => Navigator.pop(context)),
          Expanded(
            child: FutureBuilder<MatchSheet>(
              future: _sheet,
              builder: (context, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator(color: AppColors.accent));
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    MatchSheetView(match: c.match, events: snap.data!.events, players: snap.data!.players),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
                      child: Text('آراء اللاعيبة', style: AppText.kicker(color: AppColors.accent)),
                    ),
                    if (c.votes.isEmpty) Text('محدش أكّد ولا اعترض لسه', style: AppText.body(12)),
                    for (final v in c.votes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${v.ok ? '✅' : '❌'} ${v.name} (${v.team})${v.note == null ? '' : ' — «${v.note}»'}',
                          style: AppText.body(13),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _button('✏️ عدّل الأحداث', AppColors.black, _editEvents),
                    _button('✓ اعتمد الماتش', AppColors.accent, () => _act('approve')),
                    _button('↺ مراجعة من الأول', AppColors.info, () => _act('reopen')),
                    _button('🚫 الغي الماتش', AppColors.danger, () => _act('void')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(String label, Color color, VoidCallback onTap) => Pressable(
    onTap: _busy ? null : onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: _busy ? AppColors.neutral500 : color, borderRadius: AppRadius.md),
      padding: const EdgeInsets.all(13),
      alignment: Alignment.center,
      child: Text(label, style: AppText.h(14, color: AppColors.white)),
    ),
  );
}
