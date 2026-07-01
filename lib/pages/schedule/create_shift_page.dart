import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

const _deFull = ['Montag','Dienstag','Mittwoch','Donnerstag','Freitag','Samstag','Sonntag'];
const _deMon  = ['Januar','Februar','MÃ¤rz','April','Mai','Juni','Juli','August',
                  'September','Oktober','November','Dezember'];

// â”€â”€ Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CreateShiftPage extends StatefulWidget {
  const CreateShiftPage({
    super.key,
    required this.date,
    this.location = '',
    this.shiftId,
    this.isNotClocked = false,
    this.initialStart,
    this.initialEnd,
  });
  final DateTime date;
  final String   location;
  final String?  shiftId;
  final bool     isNotClocked;
  final String?  initialStart; // "HH:MM"
  final String?  initialEnd;

  @override
  State<CreateShiftPage> createState() => _CreateShiftPageState();
}

class _CreateShiftPageState extends State<CreateShiftPage> {
  late DateTime _date;
  late int _startH, _startM, _endH, _endM;
  int _breakMin = 0;

  String? _activePicker; // 'start' | 'end' | 'date' | null
  bool _openShift    = false;
  String _roleName   = '';   // enum value sent to API (EMPLOYEE/MANAGER/SUPERVISOR)
  String _roleLabel  = '';   // friendly label shown in the UI
  String _employee   = '';
  String? _userId;                       // resolved employee id (required unless open shift)
  String _locationId = '';               // required by backend
  List<Map<String, dynamic>> _locations = [];
  String _label      = '';
  String _skills     = '';
  List<String> _hashtags = [];
  String _comment    = '';
  String? _fileName;
  bool _saving       = false;
  bool _showTracking = false;
  // Inline date picker
  DateTime _pickerDate = DateTime.now(); // staging value while picker is open
  // Time tracking values (mirror planned by default)
  int _tStartH = 0, _tStartM = 0, _tEndH = 0, _tEndM = 0, _tBreakMin = 0;
  String? _tActivePicker; // 'start' | 'end' | null

  @override
  void initState() {
    super.initState();
    _date       = widget.date;
    _pickerDate = widget.date;
    _startH = _parseH(widget.initialStart, 0);
    _startM = _parseM(widget.initialStart, 0);
    _endH   = _parseH(widget.initialEnd, 0);
    _endM   = _parseM(widget.initialEnd, 0);
    _loadLocations();
  }

  /// Loads the org's locations so we can attach the (backend-required) locationId.
  /// Defaults to the location matching [widget.location] by name, else the first one.
  Future<void> _loadLocations() async {
    try {
      final data = await ApiClient.instance.get('/api/locations');
      final raw  = data is List
          ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final locs = List<Map<String, dynamic>>.from(raw);
      if (!mounted) return;
      setState(() {
        _locations = locs;
        if (locs.isNotEmpty) {
          final match = locs.firstWhere(
            (l) => (l['name'] as String?) == widget.location,
            orElse: () => locs.first,
          );
          _locationId = match['id'] as String? ?? '';
        }
      });
    } catch (_) {
      // leave _locationId empty â€” _save will surface a clear message
    }
  }

  String get _locationLabel {
    if (_locationId.isEmpty) return 'Select location';
    final loc = _locations.firstWhere(
      (l) => l['id'] == _locationId,
      orElse: () => const {},
    );
    return (loc['name'] as String?) ?? 'Select location';
  }

  void _showLocationSheet() {
    if (_locations.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(
        locations:  _locations,
        selectedId: _locationId,
        onSelect:   (id) => setState(() => _locationId = id),
      ),
    );
  }

  /// Combines the chosen calendar date with a wall-clock time into a proper
  /// ISO-8601 UTC string (the backend validates with `z.string().datetime()`).
  /// Converts from local time to UTC so the time isn't shifted on display.
  String _isoDateTime(int h, int m) {
    final d = _date;
    final localDt = DateTime(d.year, d.month, d.day, h, m);
    return localDt.toUtc().toIso8601String();
  }

  int _parseH(String? s, int def) {
    if (s == null) return def;
    final parts = s.split(':');
    return parts.isNotEmpty ? (int.tryParse(parts[0]) ?? def) : def;
  }
  int _parseM(String? s, int def) {
    if (s == null) return def;
    final parts = s.split(':');
    return parts.length > 1 ? (int.tryParse(parts[1]) ?? def) : def;
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}';

  String get _dateLabel {
    final d = _deFull[_date.weekday - 1];
    return '$d ${_date.day}. ${_deMon[_date.month - 1]}';
  }

  void _toggleDatePicker() {
    setState(() {
      if (_activePicker == 'date') {
        _activePicker = null;
      } else {
        _activePicker = 'date';
        _pickerDate   = _date;
      }
    });
  }

  void _confirmDate() {
    setState(() { _date = _pickerDate; _activePicker = null; });
  }

  void _showAddressSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressSheet(
        onSelect: (addr) => setState(() => _comment = addr.isEmpty ? _comment : addr),
      ),
    );
  }

  Future<void> _showRoleSheet() async {
    // Values must match the backend ShiftRole enum (EMPLOYEE/MANAGER/SUPERVISOR).
    const roles = [
      (label: 'Employee',   value: 'EMPLOYEE'),
      (label: 'Manager',    value: 'MANAGER'),
      (label: 'Supervisor', value: 'SUPERVISOR'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleSheet(
        roles: roles,
        selectedValue: _roleName,
        onSelect: (value, label) =>
            setState(() { _roleName = value; _roleLabel = label; }),
      ),
    );
  }

  void _showMembersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MembersSheet(
        selected: _employee,
        onSelect: (id, name) => setState(() { _userId = id; _employee = name; }),
      ),
    );
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles();
    if (r != null && mounted) setState(() => _fileName = r.files.single.name);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete shift'),
        content: const Text('Are you sure you want to delete this shift?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient.instance.delete('/api/shifts/${widget.shiftId}');
      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    // â”€â”€ Client-side validation (matches backend createShiftSchema) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    if (_locationId.isEmpty) {
      _snack('Please select a location'); return;
    }
    if (_roleName.isEmpty) {
      _snack('Please select a role'); return;
    }
    if (!_openShift && (_userId == null || _userId!.isEmpty)) {
      _snack('Please select an employee, or turn on "open shift"'); return;
    }

    setState(() => _saving = true);
    try {
      final iso = _date.toIso8601String().split('T')[0];
      final body = {
        'locationId':   _locationId,
        'date':         iso,
        'startTime':    _isoDateTime(_startH, _startM),
        'endTime':      _isoDateTime(_endH, _endM),
        'breakMinutes': _breakMin,
        'isOpenShift':  _openShift,
        'role':         _roleName,
        if (!_openShift && _userId != null) 'userId': _userId,
        if (_label.isNotEmpty)    'label':    _label,
        if (_skills.isNotEmpty)   'skills':   _skills,
        if (_hashtags.isNotEmpty) 'hashtags': _hashtags,
        if (_comment.isNotEmpty)  'shiftAddress': _comment,
      };
      if (widget.shiftId != null) {
        await ApiClient.instance.put('/api/shifts/${widget.shiftId}', data: body);
      } else {
        await ApiClient.instance.post('/api/shifts', data: body);
      }
      if (!mounted) return;
      Navigator.pop(context, 'saved');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = widget.location.isNotEmpty ? widget.location : 'Create Shift';

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Save',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ "Shift not clocked" banner (edit mode) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (widget.isNotClocked)
              Container(
                width: double.infinity,
                color: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: const Text(
                  'Shift not clocked',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),

            // â”€â”€ Date row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: _toggleDatePicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 20, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(_dateLabel,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500,
                            color: cs.onSurface)),
                    const Spacer(),
                    if (_activePicker == 'date')
                      GestureDetector(
                        onTap: _confirmDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('OK',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // â”€â”€ Inline date picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_activePicker == 'date') ...[
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _pickerDate,
                  onDateTimeChanged: (dt) => setState(() => _pickerDate = dt),
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            ],

            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ START / END / BREAK columns â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  _TimeColumn(
                    label: 'START',
                    value: _fmt(_startH, _startM),
                    active: _activePicker == 'start',
                    onTap: () => setState(() =>
                        _activePicker = _activePicker == 'start' ? null : 'start'),
                  ),
                  _vDiv(cs),
                  _TimeColumn(
                    label: 'END',
                    value: _fmt(_endH, _endM),
                    active: _activePicker == 'end',
                    onTap: () => setState(() =>
                        _activePicker = _activePicker == 'end' ? null : 'end'),
                  ),

                  _vDiv(cs),
                  _BreakColumn(
                    value: _breakMin,
                    cs: cs,
                    onChanged: (v) => setState(() => _breakMin = v),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Inline time picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_activePicker != null) ...[
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: true,
                        initialDateTime: DateTime(
                          2000, 1, 1,
                          _activePicker == 'start' ? _startH : _endH,
                          _activePicker == 'start' ? _startM : _endM,
                        ),
                        onDateTimeChanged: (dt) => setState(() {
                          if (_activePicker == 'start') {
                            _startH = dt.hour; _startM = dt.minute;
                          } else {
                            _endH = dt.hour;   _endM   = dt.minute;
                          }
                        }),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_activePicker == 'start') {
                          _activePicker = 'end';
                        } else {
                          _activePicker = null;
                        }
                      }),
                      child: Container(
                        width: 44, height: 44,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_forward,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            ],

            // â”€â”€ Time tracking section (when expanded) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_showTracking) ...[
              Container(
                width: double.infinity,
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text('TIME TRACKING:',
                    style: TextStyle(
                        fontSize: 12, letterSpacing: 0.5,
                        color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.access_time_outlined,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    _TimeColumn(
                      label: 'START',
                      value: _fmt(_tStartH, _tStartM),
                      active: _tActivePicker == 'start',
                      onTap: () => setState(() =>
                          _tActivePicker = _tActivePicker == 'start' ? null : 'start'),
                    ),
                    _vDiv(cs),
                    _TimeColumn(
                      label: 'END',
                      value: _fmt(_tEndH, _tEndM),
                      active: _tActivePicker == 'end',
                      onTap: () => setState(() =>
                          _tActivePicker = _tActivePicker == 'end' ? null : 'end'),
                    ),
                    _vDiv(cs),
                    _BreakColumn(value: _tBreakMin, cs: cs,
                        onChanged: (v) => setState(() => _tBreakMin = v)),
                  ],
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
              if (_tActivePicker != null) ...[
                SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: false,
                          initialDateTime: DateTime(
                            2000, 1, 1,
                            _tActivePicker == 'start' ? _tStartH : _tEndH,
                            _tActivePicker == 'start' ? _tStartM : _tEndM,
                          ),
                          onDateTimeChanged: (dt) => setState(() {
                            if (_tActivePicker == 'start') {
                              _tStartH = dt.hour; _tStartM = dt.minute;
                            } else {
                              _tEndH = dt.hour; _tEndM = dt.minute;
                            }
                          }),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _tActivePicker =
                              _tActivePicker == 'start' ? 'end' : null;
                        }),
                        child: Container(
                          width: 44, height: 44,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
              ],
            ],

            // â”€â”€ Add time tracking link â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: () => setState(() {
                _showTracking = !_showTracking;
                if (_showTracking) {
                  // Pre-fill from planned values
                  _tStartH = _startH; _tStartM = _startM;
                  _tEndH   = _endH;   _tEndM   = _endM;
                  _tBreakMin = _breakMin;
                } else {
                  _tActivePicker = null;
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      _showTracking ? 'Hide time tracking' : 'Add time tracking',
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Select location (required) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: _showLocationSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.business_outlined,
                        size: 20,
                        color: _locationId.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _locationLabel,
                      style: TextStyle(
                          fontSize: 15,
                          color: _locationId.isEmpty ? cs.onSurfaceVariant : cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Select role â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: _showRoleSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.work_outline,
                        size: 20,
                        color: _roleName.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _roleName.isEmpty ? 'Select role' : _roleLabel,
                      style: TextStyle(
                          fontSize: 15,
                          color: _roleName.isEmpty ? cs.onSurfaceVariant : cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Open shift toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Switch(
                    value: _openShift,
                    onChanged: (v) => setState(() => _openShift = v),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text('open shift',
                      style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Employee â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: _showMembersSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 20,
                        color: _employee.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _employee.isEmpty ? 'Employee' : _employee,
                      style: TextStyle(
                          fontSize: 15,
                          color: _employee.isEmpty ? cs.onSurfaceVariant : cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Label â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TextRow(
              icon: Icons.label_outline,
              hint: 'Label',
              value: _label,
              cs: cs,
              onChanged: (v) => setState(() => _label = v),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Skills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TextRow(
              icon: Icons.verified_user_outlined,
              hint: 'Skills (comma-separated)',
              value: _skills,
              cs: cs,
              onChanged: (v) => setState(() => _skills = v),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Hashtags â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _HashtagsRow(
              hashtags: _hashtags,
              cs: cs,
              onChanged: (tags) => setState(() => _hashtags = tags),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Upload file â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            GestureDetector(
              onTap: _pickFile,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.insert_drive_file_outlined,
                        size: 20, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload, size: 16, color: Colors.white),
                      label: Text(_fileName ?? 'Upload file',
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Address â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            InkWell(
              onTap: _showAddressSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 20, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text('choose adress',
                        style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            Divider(height: 1, indent: 48, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Comment â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _TextRow(
              icon: Icons.chat_bubble_outline,
              hint: 'Comment',
              value: _comment,
              cs: cs,
              onChanged: (v) => setState(() => _comment = v),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

            // â”€â”€ Delete shift (edit mode only) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (widget.shiftId != null) ...[
              InkWell(
                onTap: _delete,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text('Delete shift',
                      style: TextStyle(
                          fontSize: 15,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500)),
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _vDiv(ColorScheme cs) => Container(
    width: 1,
    height: 48,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: cs.outline.withValues(alpha: 0.2),
  );
}

// â”€â”€ Time columns â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({required this.label, required this.value,
      required this.active, required this.onTap});
  final String label, value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w300,
                  color: active ? AppColors.primary : cs.onSurface)),
        ],
      ),
    );
  }
}

class _BreakColumn extends StatelessWidget {
  const _BreakColumn({required this.value, required this.cs, required this.onChanged});
  final int value;
  final ColorScheme cs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('BREAK',
          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Row(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w300,
                  color: cs.onSurface)),
        ],
      ),
    ],
  );
}

// â”€â”€ Row helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MutedRow extends StatelessWidget {
  const _MutedRow({required this.icon, required this.label,
      required this.cs, required this.color});
  final IconData icon;
  final String   label;
  final ColorScheme cs;
  final Color    color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 15, color: color)),
      ],
    ),
  );
}

class _TextRow extends StatelessWidget {
  const _TextRow({required this.icon, required this.hint, required this.value,
      required this.cs, required this.onChanged});
  final IconData  icon;
  final String    hint, value;
  final ColorScheme cs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 20, color: value.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            onChanged: onChanged,
            style: TextStyle(fontSize: 15, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    ),
  );
}

// â”€â”€ Hashtag row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HashtagsRow extends StatelessWidget {
  const _HashtagsRow({required this.hashtags, required this.cs, required this.onChanged});
  final List<String> hashtags;
  final ColorScheme  cs;
  final ValueChanged<List<String>> onChanged;

  void _showSheet(BuildContext context) {
    final ctrl = TextEditingController();
    final current = List<String>.from(hashtags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.tag, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Hashtags', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const Spacer(),
                    TextButton(
                      onPressed: () { onChanged(current); Navigator.pop(ctx); },
                      child: const Text('Done', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (current.isNotEmpty) Wrap(
                    spacing: 8, runSpacing: 6,
                    children: current.map((tag) => Chip(
                      label: Text('#$tag', style: TextStyle(fontSize: 13, color: cs.onSurface)),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                      deleteIcon: Icon(Icons.close, size: 14, color: cs.onSurfaceVariant),
                      onDeleted: () => setS(() => current.remove(tag)),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  if (current.isNotEmpty) const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: ctrl,
                        autofocus: true,
                        style: TextStyle(fontSize: 15, color: cs.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add hashtag...',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant),
                          prefixText: '#',
                          prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (v) {
                          final tag = v.trim().replaceAll('#', '');
                          if (tag.isNotEmpty && !current.contains(tag)) {
                            setS(() { current.add(tag); ctrl.clear(); });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final tag = ctrl.text.trim().replaceAll('#', '');
                        if (tag.isNotEmpty && !current.contains(tag)) {
                          setS(() { current.add(tag); ctrl.clear(); });
                        }
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                      child: const Text('Add'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _showSheet(context),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(Icons.tag, size: 20,
            color: hashtags.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
        const SizedBox(width: 12),
        if (hashtags.isEmpty)
          Text('Hashtags', style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant))
        else
          Expanded(
            child: Wrap(
              spacing: 6, runSpacing: 4,
              children: hashtags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text('#$t', style: const TextStyle(
                    fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
          ),
        const Spacer(),
        Icon(Icons.add, size: 18, color: cs.onSurfaceVariant),
      ]),
    ),
  );
}

// â”€â”€ Role picker sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RoleSheet extends StatelessWidget {
  const _RoleSheet({required this.roles, required this.selectedValue, required this.onSelect});
  final List<({String label, String value})> roles;
  final String selectedValue;
  final void Function(String value, String label) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Switch',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          ...roles.asMap().entries.map((entry) {
            final r = entry.value;
            const colors = [
              Color(0xFF4CAF50), // Admin â€” green
              Color(0xFFE53935), // GeschÃ¤ftsfÃ¼hrer â€” red
              Color(0xFFFF9800), // Manager â€” orange
              Color(0xFF2196F3), // Sachkunde â€” blue
              Color(0xFF8BC34A), // Schichtleiter â€” light green
              Color(0xFFE91E63), // Sicherheitspersonal â€” pink
            ];
            final dotColor = colors[entry.key % colors.length];
            return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () { onSelect(r.value, r.label); Navigator.pop(context); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: dotColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(r.label,
                        style: TextStyle(
                            fontSize: 15,
                            color: r.value == selectedValue ? AppColors.primary : cs.onSurface)),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            ],
          );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// â”€â”€ Address picker sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/api/locations');
      final raw  = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      if (mounted) setState(() {
        _locations = List<Map<String, dynamic>>.from(raw as List);
        _loading   = false;
      });
    } catch (_) {
      if (mounted) setState(() { _locations = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('choose adress',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _locations.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                itemBuilder: (_, i) {
                  final loc  = _locations[i];
                  final name = loc['name']    as String? ?? '';
                  final addr = loc['address'] as String? ?? '';
                  final display = addr.isNotEmpty ? addr : name;
                  return InkWell(
                    onTap: () { widget.onSelect(display); Navigator.pop(context); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Text(display,
                          style: TextStyle(fontSize: 15, color: cs.onSurface)),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            InkWell(
              onTap: () { widget.onSelect(''); Navigator.pop(context); },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: const Text('Without address',
                    style: TextStyle(fontSize: 15, color: AppColors.error)),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// â”€â”€ Location picker sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LocationSheet extends StatelessWidget {
  const _LocationSheet({
    required this.locations,
    required this.selectedId,
    required this.onSelect,
  });
  final List<Map<String, dynamic>> locations;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Select location',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: locations.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
              itemBuilder: (_, i) {
                final loc  = locations[i];
                final id   = loc['id']   as String? ?? '';
                final name = loc['name'] as String? ?? '';
                final addr = loc['address'] as String? ?? '';
                return InkWell(
                  onTap: () { onSelect(id); Navigator.pop(context); },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                fontSize: 15,
                                color: id == selectedId ? AppColors.primary : cs.onSurface,
                                fontWeight: id == selectedId
                                    ? FontWeight.w600 : FontWeight.w400)),
                        if (addr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(addr,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

// â”€â”€ Select members sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MembersSheet extends StatefulWidget {
  const _MembersSheet({required this.selected, required this.onSelect});
  final String selected;
  final void Function(String id, String name) onSelect;

  @override
  State<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends State<_MembersSheet> {
  List<({String id, String name})> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/api/users');
      final raw  = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final members = (raw as List<dynamic>)
          .map((u) {
            final m = u as Map<String, dynamic>;
            final f = m['firstName'] as String? ?? '';
            final l = m['lastName']  as String? ?? '';
            return (id: m['id'] as String? ?? '', name: '$f $l'.trim());
          })
          .where((e) => e.name.isNotEmpty && e.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() { _members = members; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _members = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                  ),
                  const Expanded(
                    child: Text('Select members',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: _members.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                      itemBuilder: (_, i) {
                        final m = _members[i];
                        return InkWell(
                          onTap: () { widget.onSelect(m.id, m.name); Navigator.pop(context); },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Text(m.name,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: m.name == widget.selected
                                        ? AppColors.primary : cs.onSurface,
                                    fontWeight: m.name == widget.selected
                                        ? FontWeight.w600 : FontWeight.w400)),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }
}
