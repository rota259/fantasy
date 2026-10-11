import '../../../core/supabase/supabase_service.dart';
import 'fairplay_repository.dart';

/// تنفيذ FairPlayRepository فوق betting_reports + report_betting / admin_betting_reports.
class SupabaseFairPlayRepository implements FairPlayRepository {
  @override
  Future<void> report(String suspect, String details, {String? userId}) async {
    await SupabaseService.client.rpc(
      'report_betting',
      params: {'p_suspect': suspect.trim(), 'p_details': details.trim(), 'p_user': userId},
    );
  }

  @override
  Future<List<BettingReport>> adminReports() async {
    final rows = await SupabaseService.client.rpc('admin_betting_reports') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        (
          id: r['id'].toString(),
          reporter: (r['reporter_name'] ?? '—') as String,
          zone: (r['zone'] ?? '—') as String,
          suspect: r['suspect'] as String,
          details: r['details'] as String,
          status: r['status'] as String,
          createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
          suspectUserId: r['suspect_user'] as String?,
          suspectBanned: r['suspect_user'] != null && r['suspect_active'] == false,
        ),
    ];
  }

  @override
  Future<bool> setStatus(String id, String status) async {
    final banned = await SupabaseService.client.rpc('resolve_betting_report', params: {'p_id': id, 'p_status': status});
    return banned == true;
  }
}
