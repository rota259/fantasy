import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/player_model.dart';

class PlayerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PlayerModel>> getAllPlayers() async {
    final snapshot = await _firestore.collection('players').get();
    return snapshot.docs.map((doc) => PlayerModel.fromMap(doc.data())).toList();
  }

  Future<void> addPlayer(PlayerModel player) async {
    await _firestore.collection('players').doc(player.playerId).set(player.toMap());
  }

  Future<void> updatePlayer(PlayerModel player) async {
    await _firestore.collection('players').doc(player.playerId).update(player.toMap());
  }

  Future<void> deletePlayer(String playerId) async {
    await _firestore.collection('players').doc(playerId).delete();
  }
}
