import '../../../core/supabase/supabase_service.dart';
import 'models/poll.dart';
import 'polls_repository.dart';

/// تنفيذ PollsRepository فوق polls / poll_options / poll_votes.
class SupabasePollsRepository implements PollsRepository {
  @override
  Future<PollView?> latestPoll(String kind, String userId) async {
    final polls = await SupabaseService.table(
      'polls',
    ).select().eq('kind', kind).order('created_at', ascending: false).limit(1);
    if (polls.isEmpty) return null;
    return _view(Poll.fromMap(polls.first), userId);
  }

  @override
  Future<PollView?> tieFor(DateTime windowEnd, String userId) async {
    final polls = await SupabaseService.table(
      'polls',
    ).select().eq('kind', PollKind.totwTie).eq('window_end', windowEnd.toUtc().toIso8601String()).limit(1);
    if (polls.isEmpty) return null;
    return _view(Poll.fromMap(polls.first), userId);
  }

  Future<PollView> _view(Poll poll, String userId) async {
    final optRows = await SupabaseService.table('poll_options').select().eq('poll_id', poll.id).order('id');
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
    await SupabaseService.table(
      'poll_votes',
    ).upsert({'poll_id': pollId, 'option_id': optionId, 'user_id': userId}, onConflict: 'poll_id,user_id');
  }

  @override
  Future<String> createAward(String kind, String question, List<NewPollOption> options, DateTime? closesAt) async {
    // تصويت واحد مفتوح من كل نوع — القديم بيتقفل
    await SupabaseService.table('polls').update({'active': false}).eq('kind', kind).eq('active', true);
    final rows = await SupabaseService.table('polls')
        .insert({
          'kind': kind,
          'question': question,
          'active': true,
          if (closesAt != null) 'closes_at': closesAt.toUtc().toIso8601String(),
        })
        .select('id');
    final pollId = rows.first['id'].toString();
    await SupabaseService.table('poll_options').insert([
      for (final o in options)
        {'poll_id': pollId, 'label': o.label, 'player_id': o.playerId, 'video_url': o.videoUrl, 'match_id': o.matchId},
    ]);
    return pollId;
  }

  @override
  Future<String> createSeasonAward(String kind) async {
    final id = await SupabaseService.client.rpc('create_season_award', params: {'p_kind': kind});
    return id.toString();
  }
}
