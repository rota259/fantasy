import 'package:fantasy_5omasi/screens/manager/invitations/invitations_screen.dart';
import 'package:fantasy_5omasi/screens/manager/league/league_screen.dart';
import 'package:fantasy_5omasi/screens/manager/team/team_screen.dart';
import 'package:fantasy_5omasi/screens/user/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class FantasyHubManager extends StatefulWidget {
  const FantasyHubManager({super.key});

  @override
  State<FantasyHubManager> createState() => _FantasyHubManagerState();
}

class _FantasyHubManagerState extends State<FantasyHubManager> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TeamScreen(),
    LeagueScreen(),
    InvitationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'الفريق'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'الدوري'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'الدعوات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الملف الشخصي'),
        ],
      ),
    );
  }
}
