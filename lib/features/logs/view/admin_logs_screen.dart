import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/status_bar.dart';
import '../../matches/widgets/match_format.dart';
import '../data/logs_repository.dart';

part 'admin_logs_screen_sections.dart';
part 'admin_logs_screen_rows.dart';

/// (أدمن) السجلات: إيه اللي باظ · إمتى · عند مين · وليه.
///   فوق: أرقام آخر ساعة/يوم + نبض السيرفر + أكتر الأخطاء · تحت: السطور مع فلتر وبحث برقم الطلب.
class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  // setState محمي (protected) — الأجزاء المنقولة لملفات تانية بتحدّث الشاشة من هنا
  void _update(VoidCallback fn) => setState(fn);

  static const _filters = [('problems', 'المشاكل'), ('error', 'أخطاء'), ('warn', 'تحذيرات'), (null, 'الكل')];

  final _repo = const LogsRepository();
  final _search = TextEditingController();
  String? _level = 'problems';
  String _appLevel = 'info';
  LogStats? _stats;
  List<LogRow>? _rows;
  String? _error;
  bool _more = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String? get _query => _search.text.trim().isEmpty ? null : _search.text.trim();

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await Future.wait([_repo.stats(), _repo.list(level: _level, search: _query), _repo.level()]);
      if (!mounted) return;
      setState(() {
        _stats = res[0] as LogStats;
        _rows = res[1] as List<LogRow>;
        _appLevel = res[2] as String;
        _more = _rows!.length >= 80;
      });
    } catch (e) {
      if (mounted) setState(() => _error = dbMessage(e));
    }
  }

  Future<void> _loadMore() async {
    final rows = _rows;
    if (rows == null || rows.isEmpty) return;
    try {
      final next = await _repo.list(level: _level, search: _query, before: rows.last.id);
      if (mounted) setState(() => (_rows = [...rows, ...next], _more = next.length >= 80));
    } catch (_) {}
  }

  Future<void> _setLevel(String level) async {
    try {
      await _repo.setLevel(level);
      if (mounted) setState(() => _appLevel = level);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dbMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const StatusArea(),
          Masthead(title: 'السجلات', subtitle: 'ADMIN · LOGS', onBack: () => Navigator.pop(context)),
          Expanded(
            child: _error != null
                ? Center(
                    child: Text(_error!, style: AppText.body(13, color: AppColors.danger)),
                  )
                : _rows == null
                ? const SkeletonList()
                : RefreshIndicator(onRefresh: _load, child: _list()),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    final rows = _rows!;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_stats != null) _statsCard(_stats!),
        _searchBar(),
        _filterChips(),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(icon: Icons.check_circle_outline, title: 'مفيش سطور', hint: 'مفيش حاجة بالفلتر ده'),
          ),
        for (final r in rows) _row(r),
        if (_more && rows.isNotEmpty) TextButton(onPressed: _loadMore, child: const Text('الأقدم')),
        _levelCard(),
      ],
    );
  }
}
