import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/prefs_service.dart';
import '../auth/login_page.dart';
import '../navigation_shell.dart';

// â”€â”€ Onboarding shell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int   _currentPage    = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeInOut);
    } else {
      await PrefsService.markOnboardingSeen();
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const NavigationShell()));
    }
  }

  void _onBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeInOut);
    }
  }

  Future<void> _onSkip() async {
    await PrefsService.markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Color(0xFF2563EB)),
                      onPressed: _onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      'Aplano',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize:   18,
                          fontWeight: FontWeight.w600,
                          color:      cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: i == _currentPage ? 32 : 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller:    _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  TrackTimePage(onSkip: _onSkip, onNext: _onNext),
                  ManageSchedulePage(
                      onBack: _onBack, onNext: _onNext),
                  StayConnectedPage(onGetStarted: _onNext),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Page 1: Track Your Time â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class TrackTimePage extends StatelessWidget {
  const TrackTimePage(
      {super.key, required this.onSkip, required this.onNext});
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs   = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: onSkip,
                child: Text(l10n.onboardingSkip,
                    style: const TextStyle(
                        color:      Color(0xFF2563EB),
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
            // Illustration
            _trackTimeIllustration(context),
            const SizedBox(height: 48),
            Text(l10n.onboardingPage1Title,
                style: TextStyle(
                    fontSize:   28,
                    fontWeight: FontWeight.bold,
                    color:      cs.onSurface)),
            const SizedBox(height: 16),
            Text(l10n.onboardingPage1Body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color:    cs.onSurfaceVariant,
                    height:   1.6)),
            const SizedBox(height: 40),
            _nextButton(context, l10n),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _nextButton(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap:         onNext,
      borderRadius:  BorderRadius.circular(12),
      child: Container(
        width:  double.infinity,
        height: 50,
        decoration: BoxDecoration(
            color:        const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(l10n.next,
              style: const TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                  color:      Colors.white)),
        ),
      ),
    );
  }

  Widget _trackTimeIllustration(BuildContext context) {
    return Container(
      width: 280, height: 280,
      decoration: BoxDecoration(
          color:        const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(32)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160, height: 180,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset:     const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    margin: const EdgeInsets.all(12),
                    height: 8, width: 80,
                    decoration: BoxDecoration(
                        color:        const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 20),
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(
                      color: Color(0xFF2563EB), shape: BoxShape.circle),
                  child: const Icon(Icons.access_time_filled,
                      size: 32, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Container(
                    width: 100, height: 24,
                    decoration: BoxDecoration(
                        color:        const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12))),
              ],
            ),
          ),
          Positioned(
            top: 40, right: 40,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color:  const Color(0xFFDCFCE7),
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                      color:      Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.check,
                  color: Color(0xFF22C55E), size: 20),
            ),
          ),
          Positioned(
            bottom: 60, left: 30,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color:  const Color(0xFFFFEDD5),
                shape:  BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const Icon(Icons.coffee,
                  color: Color(0xFFEA580C), size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Page 2: Manage Schedule â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ManageSchedulePage extends StatelessWidget {
  const ManageSchedulePage(
      {super.key, required this.onBack, required this.onNext});
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs   = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: Theme.of(context).platform == TargetPlatform.iOS
                ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
                : const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Schedule preview card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:        Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset:     const Offset(0, 12))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.onboardingUpcomingShifts,
                              style: const TextStyle(
                                  fontSize:      13,
                                  fontWeight:    FontWeight.w800,
                                  color:         Color(0xFF64748B),
                                  letterSpacing: 0.8)),
                          const Icon(Icons.calendar_month_outlined,
                              size: 20, color: Color(0xFF2563EB)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _shiftRow(
                          day: 'MON', date: '12',
                          title: 'Morning Shift', time: '08:00 - 16:00',
                          isSelected: true, l10n: l10n),
                      const SizedBox(height: 12),
                      _shiftRow(
                          day: 'TUE', date: '13',
                          title: 'Late Shift', time: '14:00 - 22:00',
                          subtitle: 'SARAH MILLER', isSelected: false,
                          l10n: l10n),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          color:  const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF93C5FD), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.swap_horiz,
                                color: Color(0xFF2563EB), size: 22),
                            const SizedBox(width: 12),
                            Text(l10n.onboardingTapToSwap,
                                style: const TextStyle(
                                    color:      Color(0xFF2563EB),
                                    fontWeight: FontWeight.w700,
                                    fontSize:   15)),
                            const Spacer(),
                            Icon(Icons.touch_app,
                                color: const Color(0xFF2563EB)
                                    .withValues(alpha: 0.4),
                                size: 20),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(l10n.onboardingPage2Title,
                    style: TextStyle(
                        fontSize:      34,
                        fontWeight:    FontWeight.w900,
                        color:         cs.onSurface,
                        letterSpacing: -1.0)),
                const SizedBox(height: 16),
                Text(l10n.onboardingPage2Body,
                    style: TextStyle(
                        fontSize: 17,
                        color:    cs.onSurfaceVariant,
                        height:   1.45)),
                const SizedBox(height: 32),
                _featureItem(context, Icons.people_alt_outlined,
                    l10n.onboardingTeamAvailability),
                const SizedBox(height: 16),
                _featureItem(context, Icons.notifications_none_rounded,
                    l10n.onboardingInstantUpdates),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Bottom nav bar
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(color: cs.surface),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 60),
                    side: BorderSide(color: cs.outline, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l10n.back,
                      style: TextStyle(
                          color:      cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize:   16)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 60),
                    elevation:   10,
                    shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.next,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize:   16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shiftRow({
    required String  day,
    required String  date,
    required String  title,
    required String  time,
    String?          subtitle,
    required bool    isSelected,
    required AppLocalizations l10n,
  }) {
    return Row(
      children: [
        Container(
          width: 54, height: 68,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFDBEAFE)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(day,
                  style: TextStyle(
                      fontSize:   11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8))),
              Text(date,
                  style: TextStyle(
                      fontSize:   24,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF475569))),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w800,
                              color:      Color(0xFF94A3B8))),
                    if (isSelected)
                      Text(l10n.onboardingYourShift,
                          style: const TextStyle(
                              fontSize:   10,
                              fontWeight: FontWeight.w800,
                              color:      Color(0xFFBFDBFE))),
                    Text(title,
                        style: TextStyle(
                            fontSize:   17,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF1E293B))),
                    Text(time,
                        style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : const Color(0xFF64748B))),
                  ],
                ),
                isSelected
                    ? Icon(Icons.access_time_filled,
                        color: Colors.white.withValues(alpha: 0.4), size: 24)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          'https://i.pravatar.cc/100?img=12',
                          width: 28, height: 28, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 28, height: 28,
                            color: const Color(0xFFE2E8F0),
                            child: const Icon(Icons.person,
                                size: 18, color: Color(0xFF64748B)),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureItem(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color:        const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
        ),
        const SizedBox(width: 16),
        Text(label,
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.w600,
                color:      Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

// â”€â”€ Page 3: Stay Connected â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class StayConnectedPage extends StatelessWidget {
  const StayConnectedPage({super.key, required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs   = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(l10n.onboardingPage3Title,
                style: TextStyle(
                    fontSize:   32,
                    fontWeight: FontWeight.bold,
                    color:      cs.onSurface)),
            const SizedBox(height: 16),
            Text(l10n.onboardingPage3Body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color:    cs.onSurfaceVariant,
                    height:   1.6)),
            const SizedBox(height: 24),
            // Chat preview
            _chatPreview(context),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.onboardingGetStarted,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _chatPreview(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset:     const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
                color:        const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20)),
            child: Text(l10n.today,
                style: TextStyle(
                    fontSize:      12,
                    fontWeight:    FontWeight.w700,
                    color:         Colors.grey[600],
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 20),
          // Bot message
          _chatBubble(
            isLeft:   true,
            avatar:   const Icon(Icons.smart_toy_outlined,
                size: 20, color: Color(0xFF2563EB)),
            avatarBg: const Color(0xFFDBEAFE),
            sender:   'Aplano Bot',
            text:
                'New shift update: Monday Morning Shift has been published.',
          ),
          const SizedBox(height: 20),
          // Sarah message
          _chatBubble(
            isLeft:   true,
            avatar:   Image.network(
              'https://i.pravatar.cc/150?img=5',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person, color: Color(0xFF818CF8)),
            ),
            avatarBg: const Color(0xFFE0E7FF),
            sender:   'Sarah Chen',
            text:
                "Hey team, can anyone cover my shift tomorrow? I'm feeling a bit under the weather. ðŸ¤’",
          ),
          const SizedBox(height: 20),
          // Own reply
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:     const EdgeInsets.all(12),
              decoration:  const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.only(
                  topLeft:     Radius.circular(16),
                  topRight:    Radius.circular(4),
                  bottomLeft:  Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const Text(
                "I've got it covered, Sarah! Just confirmed in the schedule.",
                style: TextStyle(
                    fontSize: 14, color: Colors.white, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble({
    required bool   isLeft,
    required Widget avatar,
    required Color  avatarBg,
    required String sender,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: avatarBg, borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(12), child: avatar),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender,
                  style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      Color(0xFF475569))),
              const SizedBox(height: 4),
              Container(
                padding:     const EdgeInsets.all(12),
                decoration:  BoxDecoration(
                    color:        const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16)),
                child: Text(text,
                    style: const TextStyle(
                        fontSize: 14,
                        color:    Color(0xFF334155),
                        height:   1.4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}