import 'package:fantasy_5omasi/features/auth/data/models/app_user.dart';
import 'package:fantasy_5omasi/features/manager/data/models/admin_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AppUser user(String role) => AppUser.fromMap({'id': 'u', 'name': 'علي', 'email': 'a@b.c', 'role': role});

  test('الأدوار: أدمن · مدير منطقة · يوزر', () {
    expect((user('manager').isManager, user('manager').isOrganizer), (true, false));
    expect((user('organizer').isManager, user('organizer').isOrganizer), (false, true));
    expect(user('organizer').canOrganize, isTrue);
    expect(user('user').canOrganize, isFalse);
  });

  test('سجل العمليات بيتقري بالعربي', () {
    final e = AdminLogEntry.fromMap({
      'admin_name': 'كريم',
      'action': 'set_role',
      'target': 'x',
      'detail': {'role': 'organizer', 'name': 'علي'},
      'created_at': '2026-09-26T10:00:00Z',
    });
    expect(e.label, 'خلّى «علي» مدير منطقة');
    expect(e.adminName, 'كريم');
    final v = AdminLogEntry.fromMap({
      'action': 'match_void',
      'detail': {'teams': 'أ ضد ب'},
      'created_at': '2026-09-26T10:00:00Z',
    });
    expect(v.label, 'لغى ماتش أ ضد ب');
  });
}
