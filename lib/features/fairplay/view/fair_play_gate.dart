import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fair_play_screen.dart';

/// أول ما الأبلكيشن يفتح: «لا للمراهنات» لازم يوافق عليها مرة — وبعدها الأبلكيشن عادي.
class FairPlayGate extends StatefulWidget {
  const FairPlayGate({super.key, required this.child});
  final Widget child;

  static const _key = 'fair_play_ack_v1';

  @override
  State<FairPlayGate> createState() => _FairPlayGateState();
}

class _FairPlayGateState extends State<FairPlayGate> {
  bool? _acked;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) => p.getBool(FairPlayGate._key) ?? false)
        .catchError((_) => false)
        .then((v) => mounted ? setState(() => _acked = v) : null);
  }

  Future<void> _accept() async {
    setState(() => _acked = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(FairPlayGate._key, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final acked = _acked;
    if (acked == null) return const ColoredBox(color: Colors.transparent);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: acked
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : FairPlayScreen(key: const ValueKey('fair'), onAccept: _accept),
    );
  }
}
