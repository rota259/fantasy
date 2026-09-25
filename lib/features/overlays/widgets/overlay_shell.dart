import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/masthead.dart';
import '../../../core/widgets/status_bar.dart';

/// هيكل موحّد لكل الـ overlays: شريط حالة + ترويسة برجوع + محتوى + بار سفلي.
class OverlayShell extends StatelessWidget {
  const OverlayShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.children,
    this.bottomBar,
    this.trailing,
    this.header,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final List<Widget> children;
  final Widget? bottomBar;
  final Widget? trailing;

  /// ترويسة بديلة (لبعض الـ overlays زي شاشة اللاعب السوداء).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg,
      child: Column(
        children: [
          const StatusArea(),
          header ?? Masthead(title: title, subtitle: subtitle, onBack: onBack, trailing: trailing),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: children),
          ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}

/// بار سفلي أسود موحّد للـ overlays.
class OverlayActionBar extends StatelessWidget {
  const OverlayActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.black,
      padding: const EdgeInsets.all(16),
      child: SafeArea(top: false, child: child),
    );
  }
}
