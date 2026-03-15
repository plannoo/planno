import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../pages/dashboard/dashboard.dart';
import '../pages/schedule/teamschedule.dart';
import '../pages/time_tracking/clockin_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/profile/menu_page.dart';

/// Root navigation shell that hosts all main tabs via [IndexedStack].
///
/// Tab layout matches the design:
///   0 Dashboard  1 Schedule  2 Tracking  3 Messages  4 More
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DashboardPage(),
    TeamSchedulePage(),
    TimeClockScreen(),
    ChatPage(),
     AccountProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.grid_view_rounded,       label: 'Dashboard'),
    (icon: Icons.calendar_month_outlined, label: 'Schedule'),
    (icon: Icons.access_time_outlined,    label: 'Tracking'),
    (icon: Icons.chat_bubble_outline,     label: 'Messages'),
    (icon: Icons.menu,                    label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item     = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected ? AppColors.primary : AppColors.slate400,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? AppColors.primary : AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}