// lib/pages/navigation_shell.dart
import 'package:aplano/pages/chat/chat_page.dart';
import 'package:aplano/pages/time_tracking/clockin_page.dart';
import 'package:aplano/pages/dashboard/dashboard.dart';
import 'package:aplano/pages/profile/menu_page.dart';
import 'package:aplano/pages/notification/notification_page.dart';
import 'package:aplano/pages/schedule/teamschedule.dart';
import 'package:aplano/pages/schedule/myschedule.dart';
import 'package:aplano/pages/absence/absence_page.dart';
import 'package:flutter/material.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AplanoDashboard(), // Tab 1: Dashboard
    const MySchedulePage(), // Tab 2: My Schedule
    const TeamSchedulePage(), // Tab 3: Team Schedule
    const TimeClockScreen(), // Tab 4: Clock In/Out
    const AbsencePage(), // Tab 5: Absences
    const ChatPage(), // Tab 6: Chat
    const NotificationsPage(), // Tab 7: Notifications
    const AccountProfilePage(), // Tab 8: Profile/Menu
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.event_busy), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: ''),
        ],
      ),
    );
  }
}