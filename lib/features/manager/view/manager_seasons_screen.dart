import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';
import '../../seasons/data/season.dart';
import '../../seasons/data/seasons_repository.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/fx/skeleton.dart';

String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

/// (مدير) الموسم: البداية + نص الموسم + النهاية. من غيره الكروت مش بتشتغل.
class ManagerSeasonsScreen extends StatefulWidget {
  const ManagerSeasonsScreen({super.key});

  @override
  State<ManagerSeasonsScreen> createState() => _ManagerSeasonsScreenState();
}

class _ManagerSeasonsScreenState extends State<ManagerSeasonsScreen> {
  late final SeasonsRepository _repo = context.read<SeasonsRepository>();
  late Future<List<Season>> _future = _repo.fetchAll();
  final _name = TextEditingController();
  DateTime? _start, _mid, _end;
  String? _editingId;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _future = _repo.fetchAll();
  });

  void _edit(Season s) => setState(() {
    _editingId = s.id;
    _name.text = s.name;
    _start = s.startsAt;
    _mid = s.midAt;
    _end = s.endsAt;
  });

  Future<void> _pick(DateTime? current, ValueChanged<DateTime> set) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => set(DateTime(d.year, d.month, d.day)));
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty || _start == null || _mid == null || _end == null) {
      messenger.showSnackBar(const SnackBar(content: Text('اكتب الاسم وحدّد التواريخ التلاتة')));
      return;
    }
    final s = Season(id: _editingId ?? '', name: _name.text.trim(), startsAt: _start!, midAt: _mid!, endsAt: _end!);
    if (!s.isValid) {
      messenger.showSnackBar(const SnackBar(content: Text('الترتيب لازم: البداية ← النص ← النهاية')));
      return;
    }
    try {
      await _repo.save(s);
      setState(() {
        _editingId = null;
        _name.clear();
        _start = _mid = _end = null;
      });
      _reload();
      messenger.showSnackBar(const SnackBar(content: Text('اتحفظ الموسم ✓')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'الموسم', subtitle: 'ADMIN · SEASON', onBack: () => Navigator.pop(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'الكروت (كابتن ×٣ · الاحتياطي يتحسب · الوايلد كارد) مرتين في كل نص، والدبل مرتين في الموسم كله.',
                  style: AppText.body(12, color: AppColors.neutral700),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.md,
                    border: Border.all(color: AppColors.line, width: 1.2),
                  ),
                  child: TextField(
                    controller: _name,
                    style: AppText.h(14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                      hintText: 'اسم الموسم (مثلاً: موسم 2026)',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _date('البداية', _start, (d) => _start = d),
                    const SizedBox(width: 6),
                    _date('نص الموسم', _mid, (d) => _mid = d),
                    const SizedBox(width: 6),
                    _date('النهاية', _end, (d) => _end = d),
                  ],
                ),
                const SizedBox(height: 12),
                Pressable(
                  onTap: _save,
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: AppRadius.md),
                    padding: const EdgeInsets.all(13),
                    alignment: Alignment.center,
                    child: Text(
                      _editingId == null ? '+ اعمل موسم' : 'احفظ التعديل',
                      style: AppText.h(14, color: AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Season>>(
                  future: _future,
                  builder: (context, snap) {
                    if (!snap.hasData) return const SkeletonList();
                    if (snap.data!.isEmpty) {
                      return Text('لسه مفيش مواسم', style: AppText.body(12, color: AppColors.neutral600));
                    }
                    return Column(children: [for (final s in snap.data!) _row(s)]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _date(String label, DateTime? v, ValueChanged<DateTime> set) => Expanded(
    child: Pressable(
      onTap: () => _pick(v, set),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        child: Column(
          children: [
            Text(label, style: AppText.kicker()),
            Text(
              v == null ? 'اختار' : _fmt(v),
              style: AppText.h(12, color: v == null ? AppColors.neutral500 : AppColors.ink),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _row(Season s) => Pressable(
    behavior: HitTestBehavior.opaque,
    onTap: () => _edit(s),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: AppDecor.softDivider,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.name}${s.isCurrent() ? '  · شغّال ✓' : ''}', style: AppText.h(14)),
                Text(
                  '${_fmt(s.startsAt)} ← نص ${_fmt(s.midAt)} ← ${_fmt(s.endsAt)}',
                  style: AppText.body(10, color: AppColors.neutral700),
                ),
              ],
            ),
          ),
          Text('تعديل ›', style: AppText.h(11, color: AppColors.accent)),
        ],
      ),
    ),
  );
}
