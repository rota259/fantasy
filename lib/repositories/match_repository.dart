import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/match_model.dart';
import 'package:fantasy_5omasi/models/event_model.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MatchModel>> getAllMatches() async {
    final snapshot = await _firestore.collection('matches').get();
    return snapshot.docs.map((doc) => MatchModel.fromMap(doc.data())).toList();
  }

  Future<void> addMatch(MatchModel match) async {
    await _firestore.collection('matches').doc(match.matchId).set(match.toMap());
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    await _firestore.collection('matches').doc(matchId).update({'status': status});
  }

  Future<void> addMatchEvents(String matchId, List<EventModel> events) async {
    for (var event in events) {
      await _firestore.collection('events').doc(event.eventId).set(event.toMap());
    }
  }

  Future<List<EventModel>> getEventsByMatch(String matchId) async {
    final snapshot = await _firestore
        .collection('events')
        .where('matchId', isEqualTo: matchId)
        .get();
    return snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
  }
}
