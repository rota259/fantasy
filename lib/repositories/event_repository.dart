import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addEvent(EventModel event) async {
    await _firestore.collection('events').doc(event.eventId).set(event.toMap());
  }

  Future<void> addEvents(List<EventModel> events) async {
    for (var event in events) {
      await addEvent(event);
    }
  }

  Future<List<EventModel>> getEventsByMatch(String matchId) async {
    final snapshot = await _firestore
        .collection('events')
        .where('matchId', isEqualTo: matchId)
        .get();
    return snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
  }

  Future<List<EventModel>> getEventsByPlayer(String playerId) async {
    final snapshot = await _firestore
        .collection('events')
        .where('playerId', isEqualTo: playerId)
        .get();
    return snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
}
