import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'shift_detail_page.dart';

// ── Models ─────────────────────────────────────────────────────────────────────

class TrackingEntry {
  final String  shiftId;
  final String  name;
  final String? avatarUrl;
  final String  dateLabel;
  final String  plannedStart;
  final String  plannedEnd;
  final int     plannedBreak;
  final String  trackedStart;
  final String  trackedEnd;
  final int     trackedBreak;
  final String  status;
  // extra detail fields
  final String  locationName;
  final String  dateIso;
  final String  roleName;
  final String  label;
  final bool    isNightShift;

  const TrackingEntry({
    required this.shiftId,
    required this.name,
    this.avatarUrl,
    required this.dateLabel,
    required this.plannedStart,
    required this.plannedEnd,
    required this.plannedBreak,
    required this.trackedStart,
    required this.trackedEnd,
    required this.trackedBreak,
    required this.status,
    required this.locationName,
    required this.dateIso,
    required this.roleName,
    required this.label,
    required this.isNightShift,
  });
}

// ── Page ───────────────────────────────────────────────────────────────────────

class TimeTrackingsPage extends StatefulWidget {
  const TimeTrackingsPage({super.key});

  @override
  State<TimeTrackingsPage> createState() => _TimeTrackingsPageState();
}

class _TimeTrackingsPageState extends State<TimeTrackingsPage> {
  List<TrackingEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/api/dashboard/time-trackings')
          as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>?) ?? [];
      if (!mounted) return;
      setState(() {
        _entries = list.map((e) {
          final m = e as Map<String, dynamic>;
          return TrackingEntry(
            shiftId:      m['shiftId']      as String? ?? '',
            name:         '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim(),
            avatarUrl:    m['avatarUrl']    as String?,
            dateLabel:    m['dateLabel']    as String? ?? '',
            plannedStart: m['plannedStart'] as String? ?? '--:--',
            plannedEnd:   m['plannedEnd']   as String? ?? '--:--',
            plannedBreak: (m['plannedBreak'] as num? ?? 0).toInt(),
            trackedStart: m['trackedStart'] as String? ?? '--:--',
            trackedEnd:   m['trackedEnd']   as String? ?? '--:--',
            trackedBreak: (m['trackedBreak'] as num? ?? 0).toInt(),
            status:       m['status']       as String? ?? 'Clocked',
            locationName: m['locationName'] as String? ?? '',
            dateIso:      m['dateIso']      as String? ?? '',
            roleName:     m['roleName']     as String? ?? '',
            label:        m['label']        as String? ?? '',
            isNightShift: m['isNightShift'] as bool? ?? false,
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Time trackings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? Center(
                  child: Text('No time trackings found',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _TrackingCard(
                      entry: _entries[i],
                      onAccepted: _load,
                    ),
                  ),
                ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────

class _TrackingCard extends StatefulWidget {
  const _TrackingCard({required this.entry, required this.onAccepted});
  final TrackingEntry entry;
  final VoidCallback onAccepted;

  @override
  State<_TrackingCard> createState() => _TrackingCardState();
}

class _TrackingCardState extends State<_TrackingCard> {
  bool _expanded = false;
  bool _accepting = false;

  Future<void> _accept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    try {
      await ApiClient.instance.post(
        '/api/dashboard/accept-tracking',
        data: { 'shiftId': widget.entry.shiftId },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Time tracking accepted'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onAccepted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e       = widget.entry;
    final cs      = Theme.of(context).colorScheme;
    final isAuto  = e.status.toLowerCase().contains('auto');

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        color: cs.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row ──────────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: e.avatarUrl != null ? NetworkImage(e.avatarUrl!) : null,
                  child: e.avatarUrl == null
                      ? Text(
                          e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(e.dateLabel,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── PLANNED row ───────────────────────────────────────────────
            _TimeRow(
              label: 'PLAN\nNED',
              labelColor: cs.onSurfaceVariant,
              value: '${e.plannedStart} – ${e.plannedEnd} / ${e.plannedBreak}',
              valueColor: cs.onSurface,
            ),
            const SizedBox(height: 4),

            // ── TRACKED row ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _TimeRow(
                    label: 'TRAC\nKED',
                    labelColor: AppColors.primary,
                    value: '${e.trackedStart} – ${e.trackedEnd} / ${e.trackedBreak}',
                    valueColor: AppColors.primary,
                  ),
                ),
                Text(
                  e.status,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isAuto ? AppColors.error : cs.onSurfaceVariant),
                ),
              ],
            ),

            // ── Action buttons (expanded) ─────────────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShiftDetailPage(entry: widget.entry),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: const Text('SHOW SHIFT',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _accepting ? null : _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: _accepting
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ACCEPT',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.labelColor,
    required this.value,
    required this.valueColor,
  });
  final String label;
  final Color  labelColor;
  final String value;
  final Color  valueColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 50,
        child: Text(label,
            style: TextStyle(fontSize: 9, color: labelColor, height: 1.3)),
      ),
      Expanded(
        child: Text(value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: valueColor)),
      ),
    ],
  );
}
