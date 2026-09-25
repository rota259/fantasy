import 'package:equatable/equatable.dart';

import '../chip_type.dart';

/// حالة كارت لماتش معيّن (من دالة chip_status في السيرفر).
class ChipStatus extends Equatable {
  const ChipStatus({required this.type, required this.used, required this.limit, required this.active, this.blocked});

  final ChipType type;
  final int used; // اتستخدم كام مرة في النص/الموسم
  final int limit;
  final bool active; // مفعّل في الماتش ده
  final String? blocked; // سبب إنه مش متاح (null = متاح)

  int get left => (limit - used).clamp(0, limit);
  bool get canActivate => !active && blocked == null && left > 0;

  static ChipStatus? fromMap(Map<String, dynamic> m) {
    final type = ChipType.fromKey(m['chip'] as String?);
    if (type == null) return null;
    return ChipStatus(
      type: type,
      used: (m['used'] as num?)?.toInt() ?? 0,
      limit: (m['lim'] as num?)?.toInt() ?? 0,
      active: m['active'] == true,
      blocked: m['blocked'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, used, limit, active, blocked];
}
