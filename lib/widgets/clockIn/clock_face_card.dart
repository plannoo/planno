import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/clock_provider.dart';

/// Pill-shaped digital clock card.
///
/// Status labels (ON DUTY / ON BREAK / NOT CLOCKED IN) now come from
/// [AppLocalizations] so they switch with the app locale.
class ClockFaceCard extends StatelessWidget {
  const ClockFaceCard({
    super.key,
    required this.clockStatus,
    required this.sessionTime,
    required this.isOnBreak,
    this.breakTime,
  });

  final ClockStatus clockStatus;
  final Duration    sessionTime;
  final bool        isOnBreak;
  final Duration?   breakTime;

  bool get _isIdle => clockStatus == ClockStatus.idle;

  Color get _accentColor {
    if (isOnBreak) return AppColors.warning;
    if (!_isIdle)  return AppColors.success;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now  = DateTime.now();

    // Status label — from l10n
    final statusLabel = isOnBreak
        ? l10n.dutyStatusOnBreak
        : (!_isIdle ? l10n.dutyStatusOnDuty : l10n.clockNotClockedIn);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Pill time display ─────────────────────────────────────────
        Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(
              vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color:        const Color(0xFFF0F3FA),
            borderRadius: BorderRadius.circular(36),
          ),
          child: Column(
            children: [
              Text(
                _formatTime(now),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize:     52,
                  fontWeight:   FontWeight.w700,
                  color:        Color(0xFF1E293B),
                  letterSpacing: 2.0,
                  height:       1.0,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatDate(now),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.slate400, fontSize: 14),
              ),
            ],
          ),
        ),

        if (breakTime != null) ...[
          const SizedBox(height: 8),
          Text(
            'Break: ${_formatDuration(breakTime!)}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.slate500,
            ),
          ),
        ],

        const SizedBox(height: 14),

        // ── Status pill ───────────────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color:        _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: _accentColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width:  7,
                  height: 7,
                  decoration: BoxDecoration(
                      color: _accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize:      12,
                    fontWeight:    FontWeight.w700,
                    color:         _accentColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  String _formatDate(DateTime d) {
    const weekdays = [
      'Monday','Tuesday','Wednesday','Thursday',
      'Friday','Saturday','Sunday'
    ];
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}