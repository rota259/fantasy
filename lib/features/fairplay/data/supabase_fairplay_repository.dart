import '../../../core/supabase/supabase_service.dart';
import 'fairplay_repository.dart';

/// تنفيذ FairPlayRepository فوق betting_reports + report_betting / admin_betting_reports.
class SupabaseFairPlayRepository implements FairPlayRepository {
  @override
  Future<void> report(String suspect, String details) async {
    await SupabaseService.client.rpc(
      'report_betting',
      params: {'p_suspect': suspect.trim(), 'p_details': details.trim()},
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
        ),
    ];
  }

  @override
  Future<void> setStatus(String id, String status) async {
    await SupabaseService.table('betting_reports').update({'status': status}).eq('id', id);
  }
}
