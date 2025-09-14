import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/league_model.dart';
import 'package:fantasy_5omasi/models/user_model.dart';

class LeagueRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<LeagueModel> getLeagueById(String leagueId) async {
    final doc = await _firestore.collection('leagues').doc(leagueId).get();
    return LeagueModel.fromMap(doc.data()!);
  }

  Future<List<UserModel>> getLeagueMembers(String leagueId) async {
    final leagueDoc = await _firestore.collection('leagues').doc(leagueId).get();
    final memberIds = List<String>.from(leagueDoc.data()?['members'] ?? []);
    final users = await Future.wait(memberIds.map((uid) async {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      return UserModel.fromMap(userDoc.data()!);
    }));
    return users;
  }

  Future<void> addUserToLeague(String leagueId, String userId) async {
    final leagueRef = _firestore.collection('leagues').doc(leagueId);
    await leagueRef.update({
      'members': FieldValue.arrayUnion([userId])
    });
    await _firestore.collection('users').doc(userId).update({
      'leagueId': leagueId
    });
  }

  Future<void> createLeague(LeagueModel league) async {
    await _firestore.collection('leagues').doc(league.leagueId).set(league.toMap());
  }
}
