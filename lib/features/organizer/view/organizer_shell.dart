import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../account/view/account_screen.dart';
import 'organizer_home_screen.dart';
import '../../../core/widgets/motion.dart';

/// هيكل التطبيق لمدير المنطقة: منطقتي + حسابي بس (مفيش فريقي ولا لاعيبة ولا دوريات).
class OrganizerShell extends StatefulWidget {
  const OrganizerShell({super.key});

  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
  int _tab = 0;

  static const _items = [(Icons.sports_outlined, 'منطقتي'), (Icons.person_outline, 'حسابي')];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _tab, children: const [OrganizerHomeScreen(), AccountScreen()]),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    for (final (i, it) in _items.indexed)
                      Expanded(
                        child: Pressable(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _tab = i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(it.$1, size: 22, color: i == _tab ? AppColors.accent : AppColors.neutral600),
                              const SizedBox(height: 3),
                              Text(
                                it.$2,
                                style: AppText.body(10, color: i == _tab ? AppColors.accent : AppColors.neutral600),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
