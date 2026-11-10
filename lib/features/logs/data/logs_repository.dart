import '../../../core/supabase/supabase_service.dart';

/// سطر من السجل المركزي (جدول app_logs).
class LogRow {
  const LogRow(this.map);
  final Map<String, dynamic> map;

  int get id => (map['id'] as num).toInt();
  DateTime get at => DateTime.parse(map['ts'] as String).toLocal();
  String get level => (map['level'] ?? 'info') as String;
  String get service => (map['service'] ?? 'app') as String;
  String get event => (map['event'] ?? '') as String;
  String? get message => map['message'] as String?;
  String? get requestId => map['request_id'] as String?;
  String? get userId => map['user_id'] as String?;
  String? get route => map['route'] as String?;
  int? get status => (map['status'] as num?)?.toInt();
  int? get durationMs => (map['duration_ms'] as num?)?.toInt();
  String? get errorType => map['error_type'] as String?;
  String? get stack => map['error_stack'] as String?;
  String? get version => map['version'] as String?;
  Map<String, dynamic> get fields => Map<String, dynamic>.from((map['fields'] as Map?) ?? const {});

  bool get isProblem => level == 'error' || level == 'fatal';
}

/// أرقام لوحة السجلات (admin_log_stats).
class LogStats {
  const LogStats(this.map);
  final Map<String, dynamic> map;

  int _i(String k) => (map[k] as num?)?.toInt() ?? 0;
  int get errors1h => _i('errors_1h');
  int get errors24h => _i('errors_24h');
  int get warns24h => _i('warns_24h');
  int get failedRequests1h => _i('failed_requests_1h');
  int get p95 => _i('p95_ms_1h');
  int get usersHit => _i('users_hit_24h');
  List<({String name, int count})> get topErrors => [
    for (final e in (map['top_errors'] as List? ?? const []))
      (name: '${(e as Map)['name']}', count: (e['n'] as num).toInt()),
  ];

  /// آخر مرة المهام المجدولة في السيرفر اشتغلت (null = عمرها ما اشتغلت).
  DateTime? get serverBeat => DateTime.tryParse('${map['watch_at'] ?? map['tick_at'] ?? ''}')?.toLocal();
  bool get serverStale => serverBeat == null || DateTime.now().difference(serverBeat!).inMinutes > 15;
}

/// (أدمن) قراية السجل المركزي والتحكم في مستواه.
class LogsRepository {
  const LogsRepository();

  /// [level]: null الكل · problems (تحذير وأخطاء) · error · warn · info — [search]: رقم طلب/يوزر/اسم حدث/نوع خطأ.
  Future<List<LogRow>> list({String? level, String? search, int? before}) async {
    final rows =
        await SupabaseService.client.rpc(
              'admin_logs',
              params: {'p_level': level, 'p_search': search, 'p_limit': 80, 'p_before': before},
            )
            as List;
    return [for (final r in rows) LogRow(Map<String, dynamic>.from(r as Map))];
  }

  Future<LogStats> stats() async =>
      LogStats(Map<String, dynamic>.from(await SupabaseService.client.rpc('admin_log_stats') as Map));

  /// المستوى الحالي للأبلكيشن عند كل الناس (debug · info · warn · error).
  Future<String> level() async {
    final cfg = Map<String, dynamic>.from(await SupabaseService.client.rpc('get_app_config') as Map);
    return (cfg['log_level'] as String?) ?? 'info';
  }

  Future<void> setLevel(String level) =>
      SupabaseService.client.rpc('set_app_config', params: {'p_key': 'log_level', 'p_value': level});
}
