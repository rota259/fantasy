import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/screens/user/teamDisplay/player_card.dart';
import 'package:fantasy_5omasi/themes/app_color.dart';

class TeamDisplayScreen extends StatefulWidget {
  final String userId;
  const TeamDisplayScreen({super.key, required this.userId});

  @override
  State<TeamDisplayScreen> createState() => _TeamDisplayScreenState();
}

class _TeamDisplayScreenState extends State<TeamDisplayScreen> {
  UserModel? gk;
  List<UserModel> mids = [];
  List<UserModel> fwds = [];
  List<UserModel> bench = [];

  UserModel? selectedForSwap;
  String? captainId;
  String? viceCaptainId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormation();
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
    final gkId = data['gk'];
    final midsIds = List<String>.from(data['midfielders'] ?? []);
    final fwdsIds = List<String>.from(data['forwards'] ?? []);
    final benchIds = List<String>.from(data['bench'] ?? []);

    final allIds = [if (gkId != null) gkId, ...midsIds, ...fwdsIds, ...benchIds];

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where(FieldPath.documentId, whereIn: allIds)
        .get();

    final players = snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

    setState(() {
      gk = players.firstWhere((p) => p.uid == gkId);
      mids = players.where((p) => midsIds.contains(p.uid)).toList();
      fwds = players.where((p) => fwdsIds.contains(p.uid)).toList();
      bench = players.where((p) => benchIds.contains(p.uid)).toList();
      captainId = data['captainId'];
      viceCaptainId = data['viceCaptainId'];
      isLoading = false;
    });
  }

  void _onPlayerTap(UserModel player) {
    if (bench.contains(player)) {
      if (selectedForSwap != null && selectedForSwap!.position == player.position) {
        _swapPlayers(selectedForSwap!, player);
      }
    } else {
      _showPlayerOptions(player);
    }
  }

  void _showPlayerOptions(UserModel player) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: player.photoUrl != null
                  ? NetworkImage(player.photoUrl!)
                  : null,
              backgroundColor: Colors.grey.shade800,
            ),
            const SizedBox(height: 8),
            Text(player.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
            const Divider(height: 24, color: Colors.grey),

            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text("تبديل"),
              onTap: () {
                Navigator.pop(context);
                setState(() => selectedForSwap = player);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.red),
              title: const Text("تعيين كابتن"),
              onTap: () {
                Navigator.pop(context);
                setState(() => captainId = player.uid);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_half, color: Colors.blue),
              title: const Text("تعيين نائب كابتن"),
              onTap: () {
                Navigator.pop(context);
                setState(() => viceCaptainId = player.uid);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _swapPlayers(UserModel starter, UserModel benchPlayer) {
    setState(() {
      bench.remove(benchPlayer);
      bench.add(starter);

      if (starter.position == "GK") {
        gk = benchPlayer;
      } else if (starter.position == "MID") {
        mids.remove(starter);
        mids.add(benchPlayer);
      } else if (starter.position == "FWD") {
        fwds.remove(starter);
        fwds.add(benchPlayer);
      }

      selectedForSwap = null;
    });
  }

  Future<void> _saveFormation() async {
    final formation = {
      "gk": gk?.uid,
      "midfielders": mids.map((p) => p.uid).toList(),
      "forwards": fwds.map((p) => p.uid).toList(),
      "bench": bench.map((p) => p.uid).toList(),
      "captainId": captainId,
      "viceCaptainId": viceCaptainId,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection("formations")
        .doc(widget.userId)
        .set(formation);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ تم حفظ التشكيلة")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: const Text("عرض التشكيلة", style: TextStyle(color: AppColors.textPrimary)),
        centerTitle: true,
        backgroundColor: AppColors.secondary,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // الهجوم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fwds.map((p) => PlayerCard(
              player: p,
              isSelected: selectedForSwap?.uid == p.uid,
              isCaptain: p.uid == captainId,
              isViceCaptain: p.uid == viceCaptainId,
              onTap: () => _onPlayerTap(p),
            )).toList(),
          ),

          const SizedBox(height: 12),

          // الوسط
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: mids.map((p) => PlayerCard(
              player: p,
              isSelected: selectedForSwap?.uid == p.uid,
              isCaptain: p.uid == captainId,
              isViceCaptain: p.uid == viceCaptainId,
              onTap: () => _onPlayerTap(p),
            )).toList(),
          ),

          const SizedBox(height: 12),

          // الحارس
          if (gk != null)
            PlayerCard(
              player: gk!,
              isSelected: selectedForSwap?.uid == gk!.uid,
              isCaptain: gk!.uid == captainId,
              isViceCaptain: gk!.uid == viceCaptainId,
              onTap: () => _onPlayerTap(gk!),
            ),

          const Spacer(),

          // الدكة
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: bench.map((p) => PlayerCard(
                player: p,
                isSelected: selectedForSwap?.uid == p.uid,
                onTap: () {
                  if (selectedForSwap != null &&
                      selectedForSwap!.position == p.position) {
                    _swapPlayers(selectedForSwap!, p);
                  }
                },
              )).toList(),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: _saveFormation,
            icon: const Icon(Icons.save),
            label: const Text("حفظ التشكيلة"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),    
    );
  }
}