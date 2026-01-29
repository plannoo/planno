// lib/pages/navigation_shell.dart
import 'package:aplano/pages/chat_page.dart';
import 'package:aplano/pages/clockin_page.dart';
import 'package:aplano/pages/dashboard.dart';
import 'package:aplano/pages/menu_page.dart';
import 'package:aplano/pages/notification_page.dart';
import 'package:aplano/pages/teamschedule.dart';
import 'package:flutter/material.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AplanoDashboard(), // Tab 1: Your new Dashboard
    const TeamSchedulePage(), // Tab 2: Team Schedule
    const TimeClockScreen(), // Tab 3: Clock In/Out
    const ChatPage(), // Tab 4: Chat Page
    const NotificationsPage(), // Tab 5: Notifications
   const AccountProfilePage(), // Tab 6: Menu Page
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
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: ''),
        ],
      ),
    );
  }
}