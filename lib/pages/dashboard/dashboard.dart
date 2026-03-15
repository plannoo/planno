import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/clock_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/announcement_card.dart';
import '../../../widgets/common/quick_action_tile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────────
                // Extra top padding so the header sits well below the status bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.pagePaddingH,
                    AppDimensions.spacing2xl,   // 24 px below status bar
                    AppDimensions.buttonPaddingH,
                    0,
                  ),
                  child: const _DashboardHeader(),

                ),

                const SizedBox(height: AppDimensions.spacing2xl),

                // ── Quick Actions ─────────────────────────────────────────────
                // Padding(
                //   padding: const EdgeInsets.symmetric(
                //       horizontal: AppDimensions.pagePaddingH),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const SectionHeader(title: 'Quick Actions'),
                //       const SizedBox(height: AppDimensions.spacingXl),
                //       const _QuickActionsRow(),
                //     ],
                //   ),
                // ),

                // const SizedBox(height: AppDimensions.spacing2xl),

                // ── Announcements ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.pagePaddingH),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Announcements',
                        actionLabel: 'View all',
                        onAction: () {},
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      const _AnnouncementList(),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing2xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final isOnDuty = context.select<ClockProvider, bool>((c) => c.isOnDuty);
    final user     = auth.user;
    final greeting = context.select<DashboardProvider, String>(
      (p) => p.greetingFor(user?.firstName ?? 'there'),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Avatar ──────────────────────────────────────────────────────────
    
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryLight,
          backgroundImage: user?.avatarUrl != null
              ? NetworkImage(user!.avatarUrl!)
              : null,
          child: user?.avatarUrl == null
              ? Text(
                  user?.initials ?? 'A',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppDimensions.spacingMd),

        // ── Date · greeting · clocked-in badge ──────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formattedToday(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.slate500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: AppTextStyles.h5.copyWith(
                  fontSize: 19,
                  height: 1.2,
                ),
              ),
              if (isOnDuty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'CLOCKED IN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ── Notification bell ────────────────────────────────────────────────
        _NotificationBell(hasUnread: true),
      ],
    );
  }

  String _formattedToday() {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasUnread});

  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 22,
              color: AppColors.slate700,
            ),
          ),
          if (hasUnread)
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────────

// s
// ── Announcements ──────────────────────────────────────────────────────────────

class _AnnouncementList extends StatelessWidget {
  const _AnnouncementList();

  static const _items = [
    (
      tag:   AnnouncementTag.meeting,
      title: 'Team meeting on Friday',
      body:  'Agenda: Project milestones and quarterly goals review.',
      meta:  'Conf Room B  •  10:00 AM',
      icon:  Icons.location_on_outlined,
    ),
    (
      tag:   AnnouncementTag.urgent,
      title: 'New safety protocols',
      body:  'Please review the updated workplace safety guidelines before your next shift starts. Compliance is mandatory.',
      meta:  'Posted 2h ago',
      icon:  Icons.access_time_outlined,
    ),
    (
      tag:   AnnouncementTag.newItem,
      title: 'Welcome our new trainee',
      body:  "Join us in welcoming Sarah to the logistics team! She'll be starting with us on Monday.",
      meta:  'Posted 5h ago',
      icon:  Icons.access_time_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _items
          .map((a) => AnnouncementCard(
                tag:      a.tag,
                title:    a.title,
                body:     a.body,
                meta:     a.meta,
                metaIcon: a.icon,
              ))
          .toList(),
    );
  }
}