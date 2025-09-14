import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/player_model.dart';

class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PlayerModel>> getUserTeam(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    final data = doc.data();
    final List<String> playerIds = List<String>.from(data?['team'] ?? []);

    final players = await Future.wait(playerIds.map((id) async {
      final playerDoc = await _firestore.collection('players').doc(id).get();
      return PlayerModel.fromMap(playerDoc.data()!);
    }));

    return players;
  }

  Future<void> updateUserTeam(String userId, List<String> playerIds) async {
    await _firestore.collection('users').doc(userId).update({'team': playerIds});
  }
}
