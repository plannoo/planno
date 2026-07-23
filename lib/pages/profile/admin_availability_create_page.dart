import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/member_picker_sheet.dart';

class AdminAvailabilityCreatePage extends StatefulWidget {
  const AdminAvailabilityCreatePage({
    super.key,
    this.initialUserId   = '',
    this.initialUserName = '',
  });
  final String initialUserId;
  final String initialUserName;

  @override
  State<AdminAvailabilityCreatePage> createState() =>
      _AdminAvailabilityCreatePageState();
}

class _AdminAvailabilityCreatePageState extends State<AdminAvailabilityCreatePage> {
  String   _userId    = '';
  String   _userName  = '';
  bool     _available = true;  // Available / Unavailable
  bool     _repeating = false; // once / repeating
  DateTime? _date;             // for "once"
  DateTime? _from, _to;        // for "repeating"
  final Set<int> _weekdays = {1,2,3,4,5,6,7}; // ISO Mon=1..Sun=7
  bool     _wholeDay     = true;
  bool     _notEditable  = false;
  String   _note         = '';
  bool     _saving       = false;

  String? _activePicker; // 'date' | 'from' | null
  DateTime _picker = DateTime.now();

  @override
  void initState() {
    super.initState();
    _userId   = widget.initialUserId;
    _userName = widget.initialUserName;
  }

  bool get _canSave => _userId.isNotEmpty &&
      (_repeating ? (_from != null && _to != null) : _date != null);

  void _toggleDatePicker(String key, DateTime? initial) {
    setState(() {
      if (_activePicker == key) {
        _activePicker = null;
      } else {
        _activePicker = key;
        _picker = initial ?? DateTime.now();
      }
    });
  }

  void _pickMember() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MemberPickerSheet(
      onSelect: (id, name) => setState(() { _userId = id; _userName = name; }),
    ),
  );

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      // Maps to backend CreateAvailabilityDto.
      final body = <String, dynamic>{
        'userId':            _userId,
        'type':              _available ? 'AVAILABLE' : 'UNAVAILABLE',
        'mode':              _repeating ? 'REPEATING' : 'ONCE',
        'isWholeDay':        _wholeDay,
        'isLockedByManager': _notEditable,
        if (_note.isNotEmpty) 'note': _note,
      };
      if (_repeating) {
        body['startDate']  = _from!.toIso8601String().split('T')[0];
        body['endDate']    = _to!  .toIso8601String().split('T')[0];
        body['daysOfWeek'] = _weekdays.toList()..sort();
      } else {
        body['date'] = _date!.toIso8601String().split('T')[0];
      }
      await ApiClient.instance.post('/api/availabilities', data: body);
      if (!mounted) return;
      // Return the user we created for, so the list can switch to and show them.
      Navigator.pop(context, {'userId': _userId, 'userName': _userName});
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canSave = _canSave;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Availabilities',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    GestureDetector(
                      onTap: canSave && !_saving ? _save : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: canSave
                                  ? Colors.white60 : Colors.white.withValues(alpha: 0.25)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _saving
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Create',
                                style: TextStyle(
                                    color: canSave
                                        ? Colors.white : Colors.white.withValues(alpha: 0.45),
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member picker row
                  InkWell(
                    onTap: _pickMember,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 22,
                              color: _userName.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_userName.isEmpty ? 'Employee' : _userName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16,
                                    color: _userName.isEmpty ? cs.onSurfaceVariant : cs.onSurface)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

                  // Available / Unavailable
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: _SegmentToggle(
                      leftLabel:  'Available',
                      rightLabel: 'Unavailable',
                      isLeft:     _available,
                      rightActiveColor: AppColors.error,
                      onChanged:  (v) => setState(() => _available = v),
                    ),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

                  // once / repeating
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _SegmentToggle(
                      leftLabel:  'once',
                      rightLabel: 'repeating',
                      isLeft:     !_repeating,
                      onChanged:  (v) => setState(() {
                        _repeating = !v;
                        _activePicker = null;
                      }),
                    ),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

                  // ── ONCE: single date ─────────────────────────────────
                  if (!_repeating) ...[
                    _DateRow(
                      label:  'Date',
                      value:  _date,
                      active: _activePicker == 'date',
                      onTap:  () => _toggleDatePicker('date', _date),
                      onConfirm: () => setState(() {
                        _date = _picker; _activePicker = null;
                      }),
                    ),
                    if (_activePicker == 'date') _inlinePicker(_picker, (dt) => _picker = dt),
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  ],

                  // ── REPEATING: from + to + weekday chips ──────────────
                  if (_repeating) ...[
                    _DateRow(
                      label:  'from',
                      value:  _from,
                      active: _activePicker == 'from',
                      onTap:  () => _toggleDatePicker('from', _from),
                      onConfirm: () => setState(() {
                        _from = _picker;
                        if (_to != null && _to!.isBefore(_picker)) _to = _picker;
                        _activePicker = null;
                      }),
                    ),
                    if (_activePicker == 'from') _inlinePicker(_picker, (dt) => _picker = dt),
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                    _DateRow(
                      label:  'to',
                      value:  _to,
                      active: _activePicker == 'to',
                      onTap:  () => _toggleDatePicker('to', _to ?? _from),
                      onConfirm: () => setState(() {
                        _to = _picker; _activePicker = null;
                      }),
                      trailingDelete: _to != null,
                      onDelete: () => setState(() => _to = null),
                    ),
                    if (_activePicker == 'to') _inlinePicker(_picker, (dt) => _picker = dt),
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final dow in const [
                            (1, 'Mo'), (2, 'Tu'), (3, 'We'), (4, 'Th'),
                            (5, 'Fr'), (6, 'Sa'), (7, 'Su'),
                          ])
                            _dowChip(dow.$1, dow.$2),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  ],

                  SwitchListTile(
                    title: Text('Whole day',
                        style: TextStyle(fontSize: 16, color: cs.onSurface)),
                    value: _wholeDay,
                    onChanged: (v) => setState(() => _wholeDay = v),
                    activeThumbColor: AppColors.primary,
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  SwitchListTile(
                    title: Text('Nicht vom Mitarbeiter editierbar',
                        style: TextStyle(fontSize: 15, color: cs.onSurface)),
                    value: _notEditable,
                    onChanged: (v) => setState(() => _notEditable = v),
                    activeThumbColor: AppColors.primary,
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 22,
                            color: _note.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            onChanged: (v) => _note = v,
                            style: TextStyle(fontSize: 16, color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Note',
                              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inlinePicker(DateTime initial, ValueChanged<DateTime> onChanged) {
    return SizedBox(
      height: 200,
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initial,
        onDateTimeChanged: onChanged,
      ),
    );
  }

  Widget _dowChip(int dow, String label) {
    final active = _weekdays.contains(dow);
    return GestureDetector(
      onTap: () => setState(() {
        if (active) {
          _weekdays.remove(dow);
        } else {
          _weekdays.add(dow);
        }
      }),
      child: Container(
        width: 40, height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? AppColors.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: active
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface)),
      ),
    );
  }
}

// ── Date row with optional inline OK button ───────────────────────────────────

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label, required this.value,
    required this.active, required this.onTap, required this.onConfirm,
    this.trailingDelete = false, this.onDelete,
  });
  final String     label;
  final DateTime?  value;
  final bool       active;
  final VoidCallback onTap;
  final VoidCallback onConfirm;
  final bool       trailingDelete;
  final VoidCallback? onDelete;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 22,
                color: value == null ? cs.onSurfaceVariant : AppColors.primary),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
            const SizedBox(width: 12),
            if (value != null)
              Text(_fmt(value!),
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600, color: cs.onSurface)),
            const Spacer(),
            if (active)
              GestureDetector(
                onTap: onConfirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('OK',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              )
            else if (trailingDelete)
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Segmented toggle (with optional red color for right side) ─────────────────

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({
    required this.leftLabel, required this.rightLabel,
    required this.isLeft, required this.onChanged,
    this.rightActiveColor,
  });
  final String          leftLabel, rightLabel;
  final bool            isLeft;
  final ValueChanged<bool> onChanged;
  final Color?          rightActiveColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _seg(leftLabel,  isLeft,  () => onChanged(true),
              cs, AppColors.primary)),
          Expanded(child: _seg(rightLabel, !isLeft, () => onChanged(false),
              cs, rightActiveColor ?? AppColors.primary)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap,
      ColorScheme cs, Color activeColor) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? cs.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: active
            ? [BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4, offset: const Offset(0, 1))]
            : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? activeColor : cs.onSurface)),
    ),
  );
}
