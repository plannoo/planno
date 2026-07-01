import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  int _selectedTab = 0;

  // Absences
  List<Map<String, dynamic>> _absences = [];
  bool _loadingAbsences = false;
  bool _hasMoreAbsences = false;
  int  _absencePage = 1;

  // Shift changes
  List<Map<String, dynamic>> _shiftChanges = [];
  bool _loadingShifts = false;
  bool _hasMoreShifts = false;
  int  _shiftPage = 1;

  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAbsences(reset: true);
    _loadShiftChanges(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Absence loading ────────────────────────────────────────────────────────

  Future<void> _loadAbsences({bool reset = false}) async {
    if (_loadingAbsences) return;
    if (reset) _absencePage = 1;
    setState(() => _loadingAbsences = true);
    try {
      final data = await ApiClient.instance
          .get('/api/absences?page=$_absencePage&limit=20');
      final raw = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final items = List<Map<String, dynamic>>.from(raw);
      setState(() {
        if (reset) {
          _absences = items;
        } else {
          _absences.addAll(items);
        }
        _hasMoreAbsences = items.length >= 20;
        if (items.isNotEmpty) _absencePage++;
      });
    } catch (_) {
      // keep empty on error
    } finally {
      if (mounted) setState(() => _loadingAbsences = false);
    }
  }

  // ── Shift change loading ───────────────────────────────────────────────────

  Future<void> _loadShiftChanges({bool reset = false}) async {
    if (_loadingShifts) return;
    if (reset) _shiftPage = 1;
    setState(() => _loadingShifts = true);
    try {
      final data = await ApiClient.instance
          .get('/api/shift-changes?page=$_shiftPage&limit=20');
      final raw = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final items = List<Map<String, dynamic>>.from(raw);
      setState(() {
        if (reset) {
          _shiftChanges = items;
        } else {
          _shiftChanges.addAll(items);
        }
        _hasMoreShifts = items.length >= 20;
        if (items.isNotEmpty) _shiftPage++;
      });
    } catch (_) {
      // keep empty on error
    } finally {
      if (mounted) setState(() => _loadingShifts = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _fmtDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'APPROVED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      default:         return Colors.orange;
    }
  }

  IconData _absenceIcon(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'VACATION':     return Icons.beach_access;
      case 'SICK':         return Icons.local_hospital;
      case 'TRAINING':     return Icons.school_outlined;
      case 'OVERTIME':     return Icons.schedule_outlined;
      default:             return Icons.event_busy_outlined;
    }
  }

  String _absenceLabel(String? type) {
    const labels = {
      'VACATION':      'Vacation',
      'SICK':          'Sick Leave',
      'TRAINING':      'Training',
      'OVERTIME':      'Overtime',
      'STANDBY':       'Stand-by',
      'UNEXCUSED':     'Unexcused',
      'PREFERRED_OFF': 'Preferred Off',
    };
    return labels[(type ?? '').toUpperCase()] ?? (type ?? 'Absence');
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      appBar: AppBar(
        backgroundColor:     cs.surface,
        surfaceTintColor:    Colors.transparent,
        scrolledUnderElevation: 0,
        elevation:           0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.primary, size: 20),
        ),
        centerTitle: true,
        title: Text('Request History',
            style: AppTextStyles.h5.copyWith(color: cs.onSurface)),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color:        cs.surface,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: cs.outline.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 15, color: cs.onSurface),
                      decoration: InputDecoration(
                        hintText:       'Search requests...',
                        hintStyle:      TextStyle(color: cs.onSurfaceVariant),
                        border:         InputBorder.none,
                        isDense:        true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab selector ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:        cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _Tab('Absences', 0)),
                  Expanded(child: _Tab('Shift Changes', 1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: _selectedTab == 0
                ? _buildAbsencesList(cs)
                : _buildShiftChangesList(cs),
          ),
        ],
      ),
    );
  }

  Widget _Tab(String label, int index) {
    final cs         = Theme.of(context).colorScheme;
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:  const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color:        isSelected ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
                color:     Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset:    const Offset(0, 2)),
          ] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   14,
            fontWeight: FontWeight.w700,
            color:      isSelected ? AppColors.primary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  // ── Absence list ──────────────────────────────────────────────────────────

  Widget _buildAbsencesList(ColorScheme cs) {
    if (_loadingAbsences && _absences.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final q       = _searchCtrl.text.toLowerCase();
    final visible = q.isEmpty
        ? _absences
        : _absences.where((a) {
            final label = _absenceLabel(a['type'] as String?).toLowerCase();
            return label.contains(q);
          }).toList();

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No absence requests',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: visible.length + (_hasMoreAbsences ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= visible.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextButton(
              onPressed: _loadingAbsences ? null : () => _loadAbsences(),
              child: _loadingAbsences
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Load more',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            color: AppColors.primary, size: 18),
                      ],
                    ),
            ),
          );
        }
        final a = visible[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RequestCard(
            cs:       cs,
            icon:     _absenceIcon(a['type'] as String?),
            title:    _absenceLabel(a['type'] as String?),
            subtitle: '${_fmtDate(a['startDate'] as String? ?? a['start'] as String?)} '
                '– ${_fmtDate(a['endDate'] as String? ?? a['end'] as String?)}',
            status:   (a['status'] as String?) ?? 'PENDING',
          ),
        );
      },
    );
  }

  // ── Shift changes list ────────────────────────────────────────────────────

  Widget _buildShiftChangesList(ColorScheme cs) {
    if (_loadingShifts && _shiftChanges.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final q       = _searchCtrl.text.toLowerCase();
    final visible = q.isEmpty
        ? _shiftChanges
        : _shiftChanges.where((s) {
            final type = (s['type'] as String? ?? '').toLowerCase();
            return type.contains(q);
          }).toList();

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_outlined, size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No shift change requests',
                style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: visible.length + (_hasMoreShifts ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= visible.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: TextButton(
              onPressed: _loadingShifts ? null : () => _loadShiftChanges(),
              child: _loadingShifts
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Load more',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            color: AppColors.primary, size: 18),
                      ],
                    ),
            ),
          );
        }
        final s = visible[i];
        final date = _fmtDate(s['date'] as String? ?? s['createdAt'] as String?);
        final shift = (s['shiftName'] as String?) ??
            (s['shift'] as String?) ?? 'Shift';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RequestCard(
            cs:       cs,
            icon:     Icons.swap_horiz,
            title:    (s['type'] as String?) ?? 'Shift Change',
            subtitle: date.isNotEmpty ? '$date · $shift' : shift,
            status:   (s['status'] as String?) ?? 'PENDING',
          ),
        );
      },
    );
  }
}

// ── Request card ──────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.cs,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });
  final ColorScheme cs;
  final IconData    icon;
  final String      title, subtitle, status;

  Color get _statusColor {
    switch (status.toUpperCase()) {
      case 'APPROVED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      default:         return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
