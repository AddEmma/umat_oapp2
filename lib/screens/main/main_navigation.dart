// screens/main/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:umat_srid_oapp/screens/chat/chat_screen.dart' show ChatScreen;
import 'package:umat_srid_oapp/screens/meetings/meetings_screen.dart' show MeetingsScreen;
import 'package:umat_srid_oapp/screens/members/members_screen.dart' show MembersScreen;
import 'dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    DashboardScreen(),
    MembersScreen(),
    ChatScreen(),
    MeetingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Meetings'),
        ],
      ),
    );
  }
}
