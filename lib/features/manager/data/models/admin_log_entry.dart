import 'package:equatable/equatable.dart';

/// عملية أدمن في السجل (admin_log_list).
class AdminLogEntry extends Equatable {
  const AdminLogEntry({
    required this.adminName,
    required this.action,
    required this.target,
    required this.detail,
    required this.at,
  });

  final String adminName;
  final String action;
  final String target;
  final Map<String, dynamic> detail;
  final DateTime at;

  /// وصف العملية بالعربي.
  String get label => switch (action) {
    'set_role' =>
      detail['role'] == 'organizer' ? 'خلّى «${detail['name']}» مدير منطقة' : 'رجّع «${detail['name']}» يوزر',
    'approve_manager' => 'وافق على طلب مدير',
    'reject_manager' => 'رفض طلب مدير',
    'set_zone' => 'نقل يوزر لمنطقة تانية',
    'ban' => 'حظر «${detail['name']}»',
    'unban' => 'فك حظر «${detail['name']}»',
    'team_zone' => 'غيّر منطقة فريق «$target»',
    'match_approve' => 'اعتمد ماتش ${detail['teams'] ?? ''}',
    'match_void' => 'لغى ماتش ${detail['teams'] ?? ''}',
    'match_reopen' => 'رجّع مراجعة ماتش ${detail['teams'] ?? ''}',
    _ => action,
  };

  factory AdminLogEntry.fromMap(Map<String, dynamic> m) => AdminLogEntry(
    adminName: (m['admin_name'] ?? '—') as String,
    action: (m['action'] ?? '') as String,
    target: (m['target'] ?? '') as String,
    detail: (m['detail'] as Map<String, dynamic>?) ?? const {},
    at: DateTime.parse(m['created_at'].toString()).toLocal(),
  );

  @override
  List<Object?> get props => [adminName, action, target, detail, at];
}
