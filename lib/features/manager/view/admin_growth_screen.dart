import 'package:flutter/material.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';

/// أرقام منطقة واحدة (admin_growth).
class ZoneGrowth {
  const ZoneGrowth(this.m);
  final Map<String, dynamic> m;

  int n(String k) => (m[k] as num?)?.toInt() ?? 0;
  String get name => (m['zone_name'] ?? '') as String;
}

/// (أدمن) لوحة النمو: لكل منطقة — اليوزرز والجداد · الماتشات الأسبوع ده ضد اللي قبله ·
/// كام واحد عمل تشكيلة الجولة · الشير · البطولات الشغالة. المنطقة اللي ماتشاتها أقل من ٦ في الأسبوع فانتازيها ضعيف.
class AdminGrowthScreen extends StatefulWidget {
  const AdminGrowthScreen({super.key});

  @override
  State<AdminGrowthScreen> createState() => _AdminGrowthScreenState();
}

class _AdminGrowthScreenState extends State<AdminGrowthScreen> {
  late Future<List<ZoneGrowth>> _future = _load();

  static Future<List<ZoneGrowth>> _load() async {
    final rows = await SupabaseService.client.rpc('admin_growth') as List;
    return [for (final r in rows) ZoneGrowth(Map<String, dynamic>.from(r as Map))];
  }

  Widget _stat(String v, String label, {Color? color}) => Expanded(
    child: Column(
      children: [
        Text(v, style: AppText.h(17, color: color)),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppText.body(10, color: AppColors.neutral700),
        ),
      ],
    ),
  );

  Widget _zone(ZoneGrowth z) {
    final week = z.n('matches_week'), prev = z.n('matches_prev'), users = z.n('users');
    final pickPct = users == 0 ? 0 : (z.n('pickers') * 100 / users).round();
    final trend = week > prev ? '↑' : (week < prev ? '↓' : '=');
    return Container(
      margin: AppDecor.tileMargin,
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.tile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(z.name, style: AppText.h(15))),
              if (week < 6 && users > 0) Text('ماتشات قليلة', style: AppText.h(11, color: AppColors.danger)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('$users', 'يوزر (+${z.n('new_users')} الأسبوع ده)'),
              _stat('$week $trend', 'ماتش الأسبوع ده (اللي قبله $prev)', color: week < 6 ? AppColors.danger : null),
              _stat('$pickPct٪', 'عملوا تشكيلة الجولة'),
              _stat('${z.n('shares_week')}', 'شير الأسبوع ده'),
              _stat('${z.n('tournaments')}', 'بطولة شغالة'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Column(
      children: [
        const StatusArea(),
        Masthead(title: 'لوحة النمو', subtitle: 'GROWTH', onBack: () => Navigator.pop(context)),
        Expanded(
          child: FutureBuilder<List<ZoneGrowth>>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(dbMessage(snap.error!), style: AppText.body(13, color: AppColors.danger)),
                );
              }
              if (!snap.hasData) return const SkeletonList();
              return RefreshIndicator(
                onRefresh: () async => setState(() => _future = _load()),
                child: ListView(
                  padding: const EdgeInsets.only(top: 14, bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Text(
                        'المنطقة بتبقى ماشية لما يبقى فيها ٦ ماتشات أو أكتر في الأسبوع، ونص يوزرزها بيعملوا تشكيلة.',
                        style: AppText.body(12, color: AppColors.neutral700),
                      ),
                    ),
                    for (final z in snap.data!) _zone(z),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
