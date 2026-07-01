import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../pages/dashboard/dashboard.dart';
import '../pages/home/employee_home_page.dart';
import '../pages/schedule/teamschedule.dart';
import '../pages/schedule/myschedule.dart';
import '../pages/time_tracking/clockin_page.dart';
import '../pages/chat/chat_page.dart';
import '../pages/profile/menu_page.dart';
import '../pages/notification/notification_page.dart';
import '../pages/auth/login_page.dart';
import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notifications_provider.dart';

/// Root navigation shell — 5 tabs via [IndexedStack].
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  // Admins/managers get a 5-tab shell (team dashboard + team schedule).
  // Employees get a 6-tab shell: a Home tab (announcements + open shifts),
  // a dedicated Clock-in tab, then their own schedule. Chat / Alerts / Profile
  // are shared. Building the tab list in one place keeps the pages and the
  // bottom-nav items in sync.
  List<_TabDef> _tabsFor(bool isAdmin, AppLocalizations l10n) {
    if (isAdmin) {
      return [
        _TabDef(const DashboardPage(),     Icons.home_outlined,           l10n.navDashboard,     _Badge.announcements),
        _TabDef(const TeamSchedulePage(),  Icons.calendar_month_outlined, l10n.navSchedule),
        _TabDef(const ChatPage(),          Icons.chat_bubble_outline,     l10n.navMessages),
        _TabDef(const NotificationsPage(), Icons.notifications_outlined,  l10n.navNotifications, _Badge.notifications),
        _TabDef(const ProfilePage(),       Icons.menu,                    l10n.navMore),
      ];
    }
    return [
      _TabDef(const EmployeeHomePage(),  Icons.home_outlined,           'Home',                _Badge.announcements),
      _TabDef(const ClockPage(),         Icons.access_time_outlined,    l10n.navClock),
      _TabDef(const MySchedulePage(),    Icons.calendar_month_outlined, l10n.navSchedule),
      _TabDef(const ChatPage(),          Icons.chat_bubble_outline,     l10n.navMessages),
      _TabDef(const NotificationsPage(), Icons.notifications_outlined,  l10n.navNotifications, _Badge.notifications),
      _TabDef(const ProfilePage(),       Icons.menu,                    l10n.navMore),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_onAuthChanged);
    });
  }

  @override
  void dispose() {
    try {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onAuthChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<AuthProvider>().status == AuthStatus.unauthenticated) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n    = AppLocalizations.of(context);
    final isAdmin = context.select<AuthProvider, bool>((a) => a.isAdmin);
    final tabs    = _tabsFor(isAdmin, l10n);
    // Clamp in case the role (and tab count) changed while a later tab was active.
    final index   = _currentIndex.clamp(0, tabs.length - 1);
    return Scaffold(
      body: IndexedStack(index: index, children: [for (final t in tabs) t.page]),
      bottomNavigationBar: _BottomNav(
        tabs: tabs,
        currentIndex: index,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

enum _Badge { none, announcements, notifications }

class _TabDef {
  const _TabDef(this.page, this.icon, this.label, [this.badge = _Badge.none]);
  final Widget   page;
  final IconData icon;
  final String   label;
  final _Badge   badge;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_TabDef> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final announcementUnread =
        context.select<AnnouncementProvider, int>((p) => p.unreadCount);
    final notifUnread =
        context.select<NotificationsProvider, bool>((p) => p.hasUnread);

    int badgeFor(_Badge b) => switch (b) {
      _Badge.announcements => announcementUnread,
      _Badge.notifications => notifUnread ? 1 : 0,
      _Badge.none          => 0,
    };

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
            children: List.generate(tabs.length, (i) {
              final item     = tabs[i];
              final selected = i == currentIndex;
              final badge    = badgeFor(item.badge);
              final semanticLabel = badge > 0
                  ? '${item.label}, $badge unread'
                  : item.label;
              return Expanded(
                child: Semantics(
                  label: semanticLabel,
                  button: true,
                  selected: selected,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              item.icon,
                              size: 22,
                              color: selected ? AppColors.primary : AppColors.slate400,
                            ),
                            if (badge > 0)
                              Positioned(
                                top: -4, right: -6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    badge > 9 ? '9+' : '$badge',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}