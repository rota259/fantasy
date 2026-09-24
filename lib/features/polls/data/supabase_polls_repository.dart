import '../../../core/supabase/supabase_service.dart';
import 'models/poll.dart';
import 'polls_repository.dart';

/// تنفيذ PollsRepository فوق polls / poll_options / poll_votes.
class SupabasePollsRepository implements PollsRepository {
  @override
  Future<PollView?> latestPoll(String kind, String userId) async {
    final polls = await SupabaseService.table('polls')
        .select()
        .eq('kind', kind)
        .order('created_at', ascending: false)
        .limit(1);
    if (polls.isEmpty) return null;
    final poll = Poll.fromMap(polls.first);

    final optRows = await SupabaseService.table('poll_options').select().eq('poll_id', poll.id);
    final voteRows = await SupabaseService.table('poll_votes').select('option_id,user_id').eq('poll_id', poll.id);

    final counts = <String, int>{};
    String? myOption;
    for (final v in voteRows) {
      final oid = v['option_id'].toString();
      counts[oid] = (counts[oid] ?? 0) + 1;
      if (v['user_id'].toString() == userId) myOption = oid;
    }

    final options = optRows.map((m) {
      final o = PollOption.fromMap(m);
      return o.copyWith(votes: counts[o.id] ?? 0, mine: o.id == myOption);
    }).toList();

    return PollView(poll: poll, options: options);
  }

  @override
  Future<void> closePoll(String pollId) async {
    await SupabaseService.table('polls').update({'active': false}).eq('id', pollId);
  }

  @override
  Future<void> vote(String pollId, String optionId, String userId) async {
    await SupabaseService.table('poll_votes').upsert(
      {'poll_id': pollId, 'option_id': optionId, 'user_id': userId},
      onConflict: 'poll_id,user_id',
    );
  }

  Future<String> _create(String kind, String question, List<Map<String, dynamic>> options) async {
    // نقفل التصويتات القديمة من نفس النوع
    await SupabaseService.table('polls').update({'active': false}).eq('kind', kind);
    final rows = await SupabaseService.table('polls')
        .insert({'kind': kind, 'question': question, 'active': true}).select('id');
    final pollId = rows.first['id'].toString();
    await SupabaseService.table('poll_options')
        .insert([for (final o in options) {'poll_id': pollId, ...o}]);
    return pollId;
  }

  @override
  Future<String> createStar(List<({String id, String name})> players) {
    return _create('star', 'نجم الجولة', [
      for (final p in players) {'label': p.name, 'player_id': p.id},
    ]);
  }

  @override
  Future<String> createChallenge(String question, List<String> options) {
    return _create('challenge', question, [
      for (final o in options) {'label': o},
    ]);
  }
}
