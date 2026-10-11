import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fair_play_screen.dart';

/// تذكير «لا للمراهنات» أول ما الأبلكيشن يفتح: أول مرة، وبعدين كل ٣٠ يوم — «تمام» وتكمّل.
class FairPlayGate extends StatefulWidget {
  const FairPlayGate({super.key, required this.child});
  final Widget child;

  static const _key = 'fair_play_seen_at';
  static const _every = Duration(days: 30);

  @override
  State<FairPlayGate> createState() => _FairPlayGateState();
}

class _FairPlayGateState extends State<FairPlayGate> {
  bool? _acked;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance()
        .then((p) {
          final at = p.getInt(FairPlayGate._key);
          return at != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) < FairPlayGate._every;
        })
        .catchError((_) => false)
        .then((v) => mounted ? setState(() => _acked = v) : null);
  }

  Future<void> _accept() async {
    setState(() => _acked = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(FairPlayGate._key, DateTime.now().millisecondsSinceEpoch);
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
