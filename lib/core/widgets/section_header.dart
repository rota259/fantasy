import 'package:flutter/material.dart';

import '../theme/app_text.dart';

/// ترويسة قسم: عنوان عربي + كيكر إنجليزي/أكشن على الجنب.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.kicker,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 10),
  });

  final String title;
  final String? kicker;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(title, style: AppText.h(15)),
          const Spacer(),
          if (kicker != null) Text(kicker!, style: AppText.kicker()),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
