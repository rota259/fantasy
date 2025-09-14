import 'package:fantasy_5omasi/screens/user/teamDisplay/team_display.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fantasy_5omasi/screens/manager/home/home_screen.dart';
import 'package:fantasy_5omasi/screens/user/matches/matches_screen.dart';
import 'package:fantasy_5omasi/screens/user/profile/profile_screen.dart';
import 'package:fantasy_5omasi/screens/user/list/list_screen.dart';

class FantasyHubUser extends StatefulWidget {
  const FantasyHubUser({super.key});

  @override
  State<FantasyHubUser> createState() => _FantasyHubUserState();
}

class _FantasyHubUserState extends State<FantasyHubUser> {
  int _currentIndex = 0;
  String? userId;

  // شارات التحديث لكل تبويب (مثلاً لو فيه إشعار جديد)
  final Map<int, bool> hasBadge = {
    0: false, // الرئيسية
    1: true,  // المباريات ← مثال: فيه مباراة جديدة
    2: false, // القائمة
    3: false, // الفريق
    4: false, // الملف الشخصي
  };

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userId = user.uid;
    } else {
      userId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("⚠️ لازم تسجل دخول الأول")),
      );
    }

    final List<Widget> screens = [
      const HomeScreen(),
      const MatchesScreen(),
      ListScreen(userId: userId!),         // ← القائمة
      TeamDisplayScreen(userId: userId!,),  // ← الفريق
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          _buildNavItem(Icons.home, 'الرئيسية', 0),
          _buildNavItem(Icons.calendar_today, 'المباريات', 1),
          _buildNavItem(Icons.list_alt, 'القائمة', 2),
          _buildNavItem(Icons.group, 'فريقي', 3),
          _buildNavItem(Icons.person, 'الملف الشخصي', 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Icon(icon),
          if (hasBadge[index] ?? false)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}
