import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/themes/app_color.dart';
import 'package:flutter/material.dart';
class PlayerSlot extends StatelessWidget {
  final UserModel? player;
  final VoidCallback onTap;

  const PlayerSlot({super.key, required this.player, required this.onTap, required String position});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: player != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: player!.photoUrl != null ? NetworkImage(player!.photoUrl!) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(player!.name, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
                ],
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

