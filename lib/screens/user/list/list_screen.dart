import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/screens/user/list/add_player_modal.dart';
import 'package:fantasy_5omasi/screens/user/list/player_slot.dart';
import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';

class ListScreen extends StatefulWidget {
  final String userId;
  const 
  ListScreen({super.key, required this.userId});

  @override
  State<ListScreen> createState() => _FormationScreenState();
}

class _FormationScreenState extends State<ListScreen> {
  UserModel? gk;
  List<UserModel> defenders = [];
  List<UserModel> midfielders = [];
  List<UserModel> forwards = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormation();
  }

  List<String> get selectedIds {
    final ids = <String>[];
    if (gk != null) ids.add(gk!.uid);
    ids.addAll(defenders.map((e) => e.uid));
    ids.addAll(midfielders.map((e) => e.uid));
    ids.addAll(forwards.map((e) => e.uid));
    return ids;
  }

  Future<void> _loadFormation() async {
    final doc = await FirebaseFirestore.instance
        .collection("formations")
        .doc(widget.userId)
        .get();

    if (!doc.exists) {
      setState(() => isLoading = false);
      return;
    }

    final data = doc.data()!;
    final usersCollection = FirebaseFirestore.instance.collection("users");

    try {
      final gkDoc = await usersCollection.doc(data['gk']).get();
      final gkUser = UserModel.fromMap(gkDoc.data()!);

      final defenderDocs = await Future.wait(
        (data['defenders'] as List).map((id) => usersCollection.doc(id).get()),
      );
      final defenderUsers = defenderDocs.map((d) => UserModel.fromMap(d.data()!)).toList();

      final midfielderDocs = await Future.wait(
        (data['midfielders'] as List).map((id) => usersCollection.doc(id).get()),
      );
      final midfielderUsers = midfielderDocs.map((d) => UserModel.fromMap(d.data()!)).toList();

      final forwardDocs = await Future.wait(
        (data['forwards'] as List).map((id) => usersCollection.doc(id).get()),
      );
      final forwardUsers = forwardDocs.map((d) => UserModel.fromMap(d.data()!)).toList();

      setState(() {
        gk = gkUser;
        defenders = defenderUsers;
        midfielders = midfielderUsers;
        forwards = forwardUsers;
        isLoading = false;
      });
    } catch (e) {
      print("❌ خطأ أثناء تحميل التشكيلة: $e");
      setState(() => isLoading = false);
    }
  }

  void _openPicker(String position, int index) async {
    final selected = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddPlayerModal(selectedIds: selectedIds),
    );

    if (selected != null) {
      setState(() {
        switch (position) {
          case "GK":
            gk = selected;
            break;
          case "DEF":
            if (defenders.length > index) defenders[index] = selected;
            else defenders.add(selected);
            break;
          case "MID":
            if (midfielders.length > index) midfielders[index] = selected;
            else midfielders.add(selected);
            break;
          case "FWD":
            if (forwards.length > index) forwards[index] = selected;
            else forwards.add(selected);
            break;
        }
      });
    }
  }

  Future<void> _saveFormation() async {
    if (gk == null || defenders.length < 2 || midfielders.length < 3 || forwards.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ لازم تختار كل اللاعبين قبل الحفظ")),
      );
      return;
    }

    final formation = {
      "gk": gk!.uid,
      "defenders": defenders.map((p) => p.uid).toList(),
      "midfielders": midfielders.map((p) => p.uid).toList(),
      "forwards": forwards.map((p) => p.uid).toList(),
      "timestamp": FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection("formations")
          .doc(widget.userId)
          .set(formation);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ تم حفظ التشكيلة")),
      );
    } catch (e) {
      print("❌ خطأ أثناء الحفظ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ حصل خطأ: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text("تشكيلة الفريق", style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            PlayerSlot(position: "GK", player: gk, onTap: () => _openPicker("GK", 0)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(2, (i) => PlayerSlot(
                position: "DEF",
                player: defenders.length > i ? defenders[i] : null,
                onTap: () => _openPicker("DEF", i),
              )),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (i) => PlayerSlot(
                position: "MID",
                player: midfielders.length > i ? midfielders[i] : null,
                onTap: () => _openPicker("MID", i),
              )),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(2, (i) => PlayerSlot(
                position: "FWD",
                player: forwards.length > i ? forwards[i] : null,
                onTap: () => _openPicker("FWD", i),
              )),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveFormation,
              icon: const Icon(Icons.save),
              label: const Text("حفظ التشكيلة"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.buttonText,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
