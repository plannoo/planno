import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../models/absence.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.absence});
  final AbsenceModel absence;

  String _fmt(DateTime d) =>
      DateFormat('MMM d', Intl.defaultLocale).format(d);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        surfaceTintColor:       Colors.transparent,
        scrolledUnderElevation: 0,
        elevation:              0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Confirmation',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ── Success icon ──────────────────────────────────────────────
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 38),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Title ─────────────────────────────────────────────────────
            Text('Request Submitted',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                    fontSize: 15, color: cs.onSurfaceVariant, height: 1.5),
                children: [
                  const TextSpan(text: 'Your absence request for '),
                  TextSpan(
                    text: '${_fmt(absence.startDate)} – ${_fmt(absence.endDate)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                  const TextSpan(
                      text: ' has been sent to your manager for approval.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Request card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:        AppColors.primaryLighter,
                borderRadius: BorderRadius.circular(16),
                border:       Border.all(color: AppColors.primaryLight),
              ),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(absence.typeIcon,
                        color: absence.typeIconColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(absence.typeLabel,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: cs.onSurface)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('PENDING',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Colors.orange, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                Divider(color: AppColors.primaryLight),
                const SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${_fmt(absence.startDate)} – ${_fmt(absence.endDate)}',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.primary),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.access_time_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text('Total: ${absence.workingDays} days',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                ]),
              ]),
            ),

            const Spacer(),

            // ── Action buttons ────────────────────────────────────────────
            SizedBox(
              width:  double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View My Absences',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width:  double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
