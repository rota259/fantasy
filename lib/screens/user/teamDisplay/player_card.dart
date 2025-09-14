import 'package:flutter/material.dart';
import 'package:fantasy_5omasi/models/user_model.dart';

class PlayerCard extends StatelessWidget {
  final UserModel player;
  final bool isCaptain;
  final bool isViceCaptain;
  final bool isSelected;
  final VoidCallback onTap;

  const PlayerCard({
    super.key,
    required this.player,
    required this.onTap,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: player.photoUrl != null
                      ? NetworkImage(player.photoUrl!)
                      : null,
                  backgroundColor: Colors.grey.shade800,
                ),
                const SizedBox(height: 4),
                Text(
                  player.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isCaptain)
              const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.red,
                child: Text("C", style: TextStyle(fontSize: 10)),
              ),
            if (isViceCaptain)
              const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.blue,
                child: Text("VC", style: TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }
}
