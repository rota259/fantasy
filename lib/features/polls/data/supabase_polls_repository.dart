import '../../../core/supabase/supabase_service.dart';
import '../../../core/zone/zone_scope.dart';
import 'models/poll.dart';
import 'polls_repository.dart';

/// تنفيذ PollsRepository فوق polls / poll_options / poll_votes.
class SupabasePollsRepository implements PollsRepository {
  @override
  Future<PollView?> latestPoll(String kind, String userId) async {
    // تصويت منطقتي (اللي المديرين رشّحوا فيه) أو العام بتاع الأدمن — الأحدث
    final zone = ZoneScope.current;
    final q = SupabaseService.table('polls').select().eq('kind', kind);
    final polls = await (zone == null ? q : q.or('zone_id.eq.$zone,zone_id.is.null'))
        .order('created_at', ascending: false)
        .limit(1);
    if (polls.isEmpty) return null;
    return _view(Poll.fromMap(polls.first), userId);
  }

  @override
  Future<PollView?> tieFor(DateTime windowEnd, String userId) async {
    // تعادل منطقتي (ولو مفيش، العام)
    final zone = ZoneScope.orFilter;
    final q = SupabaseService.table(
      'polls',
    ).select().eq('kind', PollKind.totwTie).eq('window_end', windowEnd.toUtc().toIso8601String());
    final polls = await (zone == null ? q : q.or(zone)).order('zone_id', nullsFirst: false).limit(1);
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
    // تصويت عام واحد مفتوح من كل نوع — القديم العام بيتقفل (تصويتات المناطق بتاعة المديرين مش بتتلمس)
    await SupabaseService.table(
      'polls',
    ).update({'active': false}).eq('kind', kind).eq('active', true).isFilter('zone_id', null);
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
  Future<void> nominate(String kind, String matchId, String playerId, String videoUrl) async {
    await SupabaseService.client.rpc(
      'nominate_award',
      params: {'p_kind': kind, 'p_match': matchId, 'p_player': playerId, 'p_video': videoUrl.trim()},
    );
  }

  @override
  Future<void> removeNomination(String optionId) async {
    await SupabaseService.client.rpc('remove_award_nomination', params: {'p_option': optionId});
  }

  @override
  Future<List<AwardNomination>> myNominations() async {
    final rows = await SupabaseService.client.rpc('my_award_nominations') as List;
    return [
      for (final r in rows.cast<Map<String, dynamic>>())
        (
          optionId: r['option_id'].toString(),
          kind: r['kind'] as String,
          label: r['label'] as String,
          videoUrl: r['video_url'] as String?,
          votes: (r['votes'] as num?)?.toInt() ?? 0,
          open: r['open'] == true,
        ),
    ];
  }

  @override
  Future<String> createSeasonAward(String kind) async {
    final id = await SupabaseService.client.rpc('create_season_award', params: {'p_kind': kind});
    return id.toString();
  }
}
