import 'package:flutter/material.dart';

class ChipBar extends StatelessWidget {
  final Function(String chipName) onActivate;

  const ChipBar({super.key, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ActionChip(label: const Text("🎯 تريبل كابتن"), onPressed: () => onActivate("تريبل كابتن")),
        ActionChip(label: const Text("🧠 بينش بوست"), onPressed: () => onActivate("بينش بوست")),
        ActionChip(label: const Text("🔥 فري هيت"), onPressed: () => onActivate("فري هيت")),
      ],
    );
  }
}
