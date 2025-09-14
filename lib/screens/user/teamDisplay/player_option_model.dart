import 'package:flutter/material.dart';
import 'package:fantasy_5omasi/models/user_model.dart';

class PlayerOptionsModal extends StatelessWidget {
  final UserModel player;
  final bool isCaptain;
  final bool isViceCaptain;
  final VoidCallback onSetCaptain;
  final VoidCallback onSetViceCaptain;
  final VoidCallback onSwapWithBench;

  const PlayerOptionsModal({
    super.key,
    required this.player,
    required this.isCaptain,
    required this.isViceCaptain,
    required this.onSetCaptain,
    required this.onSetViceCaptain,
    required this.onSwapWithBench,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade900,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
          ),
          const SizedBox(height: 8),
          Text(player.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Divider(color: Colors.white),
          ListTile(
            leading: const Icon(Icons.star, color: Colors.red),
            title: const Text("تعيين كابتن", style: TextStyle(color: Colors.white)),
            onTap: () {
              onSetCaptain();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_half, color: Colors.blue),
            title: const Text("تعيين نائب كابتن", style: TextStyle(color: Colors.white)),
            onTap: () {
              onSetViceCaptain();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.green),
            title: const Text("تبديل مع البنك", style: TextStyle(color: Colors.white)),
            onTap: () {
              onSwapWithBench();
              Navigator.pop(context);
            },            
          ),
        ],        
      ),
    );    
  }
}