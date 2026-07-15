import 'package:flutter/material.dart';

import '../../../core/auth/require_admin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/member_picker_sheet.dart';

class AdminTimeAccountPage extends StatefulWidget {
  const AdminTimeAccountPage({super.key});

  @override
  State<AdminTimeAccountPage> createState() => _AdminTimeAccountPageState();
}

class _AdminTimeAccountPageState extends State<AdminTimeAccountPage> {
  DateTime _weekStart = _startOfWeek(DateTime.now());
  String _userId   = '';
  String _userName = '';

  int _credited = 0, _absences = 0, _quota = 0, _overtime = 0; // minutes
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    requireAdmin(context);
  }

  static DateTime _startOfWeek(DateTime d) {
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static int _isoWeek(DateTime d) {
    final thursday = d.add(Duration(days: 3 - ((d.weekday + 6) % 7)));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final start = firstThursday
        .subtract(Duration(days: (firstThursday.weekday + 6) % 7));
    return ((thursday.difference(start).inDays) ~/ 7) + 1;
  }

  String _fmtH(int min) {
    final sign = min < 0 ? '-' : '';
    final abs  = min.abs();
    final h    = abs ~/ 60;
    final m    = abs % 60;
    return '$sign${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')} h';
  }

  Future<void> _load() async {
    if (_userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final week = _isoWeek(_weekStart);
      final year = _weekStart.year;
      final data = await ApiClient.instance
          .get('/api/timesheets/?employeeId=$_userId&week=$week&year=$year');
      final wrap = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
      // Week response: { entries, summary: { totalQuotaMinutes, totalCreditedMinutes,
      //   totalOvertimeMinutes, totalBreakMinutes }, week, year }
      final summary = (wrap['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
      if (mounted) {
        setState(() {
          _credited = (summary['totalCreditedMinutes'] as num?)?.toInt() ?? 0;
          _absences = 0;
          _quota    = (summary['totalQuotaMinutes'] as num?)?.toInt() ?? 40 * 60;
          _overtime = (summary['totalOvertimeMinutes'] as num?)?.toInt()
              ?? (_credited - _quota);
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _credited = 0; _absences = 0; _quota = 40 * 60;
          _overtime = -_quota; _loading = false;
        });
      }
    }
  }

  void _pickMember() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MemberPickerSheet(
      onSelect: (id, name) {
        setState(() { _userId = id; _userName = name; });
        _load();
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cw = _isoWeek(_weekStart);

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Time account',
                          style: TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white60),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                            onPressed: () { setState(() => _weekStart =
                                _weekStart.subtract(const Duration(days: 7))); _load(); },
                          ),
                          Container(width: 1, height: 24, color: Colors.white60),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            constraints: const BoxConstraints(),
                            onPressed: () { setState(() => _weekStart =
                                _weekStart.add(const Duration(days: 7))); _load(); },
                          ),
                        ]),
                      ),
                      const SizedBox(width: 14),
                      Text('${_weekStart.year} KW $cw',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // Member chip row
          Container(
            color: cs.surface,
            child: InkWell(
              onTap: _pickMember,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 22,
                        color: _userName.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_userName.isEmpty ? 'Select member' : _userName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16, color: cs.onSurface)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _row(cs, 'Credited:',  _fmtH(_credited), bold: true),
                        _row(cs, '(absences):', _fmtH(_absences),
                            muted: true, indent: 16),
                        _row(cs, 'Quota:',     _fmtH(_quota), bold: true),
                        _row(cs, 'Overtime:',  _fmtH(_overtime),
                            bold: true,
                            valueColor: _overtime < 0 ? AppColors.error : AppColors.success),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(ColorScheme cs, String label, String value,
      {bool bold = false, bool muted = false, double indent = 0, Color? valueColor}) {
    return Container(
      padding: EdgeInsets.fromLTRB(indent, 14, 0, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: muted ? cs.onSurfaceVariant : cs.onSurface)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  color: valueColor ?? (muted ? cs.onSurfaceVariant : cs.onSurface))),
        ],
      ),
    );
  }
}
