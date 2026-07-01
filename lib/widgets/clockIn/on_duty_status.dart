import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';

/// Badge widget that displays the current on-duty status.
///
/// All three status labels (ON DUTY / OFF DUTY / ON BREAK) are read from
/// [AppLocalizations] so they switch language with the rest of the app.
class OnDutyStatus extends StatelessWidget {
  final bool         isOnDuty;
  final DutyStatusType statusType;

  const OnDutyStatus({
    super.key,
    this.isOnDuty   = true,
    this.statusType = DutyStatusType.onDuty,
  });

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final config = _getStatusConfig(l10n);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:        config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot
          Container(
            width:  8,
            height: 8,
            decoration: BoxDecoration(
                color: config.dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),

          // Status label — from l10n
          Text(
            config.label,
            style: TextStyle(
              color:         config.textColor,
              fontSize:      13,
              fontWeight:    FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(AppLocalizations l10n) {
    switch (statusType) {
      case DutyStatusType.onDuty:
        return _StatusConfig(
          label:           l10n.dutyStatusOnDuty,
          backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.15),
          dotColor:        const Color(0xFF22C55E),
          textColor:       const Color(0xFF22C55E),
        );
      case DutyStatusType.offDuty:
        return _StatusConfig(
          label:           l10n.dutyStatusOffDuty,
          backgroundColor: const Color(0xFF64748B).withValues(alpha: 0.12),
          dotColor:        const Color(0xFF64748B),
          textColor:       const Color(0xFF64748B),
        );
      case DutyStatusType.onBreak:
        return _StatusConfig(
          label:           l10n.dutyStatusOnBreak,
          backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          dotColor:        const Color(0xFFF59E0B),
          textColor:       const Color(0xFFF59E0B),
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color  backgroundColor;
  final Color  dotColor;
  final Color  textColor;

  const _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.dotColor,
    required this.textColor,
  });
}

enum DutyStatusType { onDuty, offDuty, onBreak }