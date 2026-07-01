import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'time_trackings_page.dart';

// ── Shift Detail Page ──────────────────────────────────────────────────────────

class ShiftDetailPage extends StatefulWidget {
  const ShiftDetailPage({super.key, required this.entry});
  final TrackingEntry entry;

  @override
  State<ShiftDetailPage> createState() => _ShiftDetailPageState();
}

class _ShiftDetailPageState extends State<ShiftDetailPage> {
  late String _label;
  String?        _uploadedFileName;
  PlatformFile?  _pickedFile;
  bool _saving = false;
  bool _accepted = false;

  // Editable tracked times
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _breakCtrl;

  @override
  void initState() {
    super.initState();
    _label = widget.entry.label;
    _startCtrl = TextEditingController(text: widget.entry.trackedStart);
    _endCtrl   = TextEditingController(text: widget.entry.trackedEnd);
    _breakCtrl = TextEditingController(text: '${widget.entry.trackedBreak}');
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _breakCtrl.dispose();
    super.dispose();
  }

  // Returns "Sonntag 21. Juni" format from dateIso or dateLabel
  String get _longDate {
    final de = {
      'So': 'Sonntag', 'Mo': 'Montag', 'Di': 'Dienstag', 'Mi': 'Mittwoch',
      'Do': 'Donnerstag', 'Fr': 'Freitag', 'Sa': 'Samstag',
    };
    final d = widget.entry.dateLabel; // "So 21 Juni"
    final parts = d.split(' ');
    if (parts.length >= 3) {
      final day  = de[parts[0]] ?? parts[0];
      final num  = parts[1];
      final mon  = parts[2];
      return '$day $num. $mon';
    }
    return d;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && mounted) {
      setState(() {
        _pickedFile       = result.files.single;
        _uploadedFileName = _pickedFile!.name;
      });
    }
  }

  Future<void> _uploadAttachment(String shiftId) async {
    final file = _pickedFile;
    if (file == null) return;
    final multipart = file.path != null
        ? await MultipartFile.fromFile(file.path!, filename: file.name)
        : MultipartFile.fromBytes(file.bytes ?? [], filename: file.name);
    final form = FormData.fromMap({'file': multipart});
    await ApiClient.instance.post(
        '/api/time-trackings/$shiftId/attachments', data: form);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.instance.post(
        '/api/dashboard/update-tracking',
        data: {
          'shiftId':      widget.entry.shiftId,
          'trackedStart': _startCtrl.text,
          'trackedEnd':   _endCtrl.text,
          'trackedBreak': int.tryParse(_breakCtrl.text) ?? 0,
          'label':        _label,
        },
      );
      await _uploadAttachment(widget.entry.shiftId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _accept() async {
    setState(() => _accepted = true);
    try {
      await ApiClient.instance.post('/api/dashboard/accept-tracking',
          data: { 'shiftId': widget.entry.shiftId });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _accepted = false);
    }
  }

  void _showLabelSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectLabelSheet(
        current: _label,
        onSelect: (l) => setState(() => _label = l),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final e      = widget.entry;
    final isUnconfirmed = e.status.toLowerCase().contains('unconfirmed') ||
                           !e.status.toLowerCase().contains('accept');

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
        title: Text(
          e.locationName.isNotEmpty ? e.locationName : 'Shift Detail',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Date ─────────────────────────────────────────────────────
            _Section(
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(_longDate,
                      style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            _divider(cs),

            // ── Planned row ───────────────────────────────────────────────
            _Section(
              child: Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(child: _TimeTriple(
                    startLabel: 'START', endLabel: 'END', breakLabel: 'BREAK',
                    startVal: e.plannedStart, endVal: e.plannedEnd,
                    breakVal: '${e.plannedBreak}',
                    labelColor: cs.onSurfaceVariant,
                    valColor: cs.onSurface,
                  )),
                  if (e.isNightShift)
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.nightlight_round,
                          color: Colors.white, size: 18),
                    ),
                ],
              ),
            ),

            // ── CLOCKED banner ────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: isUnconfirmed
                  ? const Color(0xFFF0F4FF)
                  : const Color(0xFFE8F5E9),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('CLOCKED: ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  Text(
                    isUnconfirmed ? '(Unconfirmed)' : '(Confirmed)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnconfirmed
                          ? const Color(0xFFF59E0B)
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tracked row ───────────────────────────────────────────────
            _Section(
              child: Row(
                children: [
                  Icon(Icons.access_time_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(child: _EditableTimeRow(
                    startCtrl: _startCtrl,
                    endCtrl:   _endCtrl,
                    breakCtrl: _breakCtrl,
                  )),
                ],
              ),
            ),

            // ── Accept row ────────────────────────────────────────────────
            GestureDetector(
              onTap: _accepted ? null : _accept,
              child: Container(
                width: double.infinity,
                color: const Color(0xFFE8F0FE),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _accepted ? 'Accepted' : 'Accept',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            _divider(cs),

            // ── Info rows ─────────────────────────────────────────────────
            _InfoRow(
              icon: Icons.work_outline,
              value: e.roleName.isNotEmpty ? e.roleName : 'No role',
              cs: cs,
            ),
            _divider(cs),
            _InfoRow(icon: Icons.person_outline, value: e.name, cs: cs),
            _divider(cs),
            _InfoRow(
              icon: Icons.label_outline,
              value: _label.isNotEmpty ? _label : 'Label',
              cs: cs,
              onTap: _showLabelSheet,
            ),
            _divider(cs),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              value: 'Skills',
              cs: cs,
              muted: true,
            ),
            _divider(cs),
            _InfoRow(
              icon: Icons.tag,
              value: 'Hashtags',
              cs: cs,
              muted: true,
            ),
            _divider(cs),

            // Upload file
            GestureDetector(
              onTap: _pickFile,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.upload_file_outlined,
                        size: 20, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.upload, size: 16, color: Colors.white),
                      label: Text(_uploadedFileName ?? 'Upload file',
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
            _divider(cs),

            // Address
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('choose adress',
                      style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _divider(ColorScheme cs) =>
      Divider(height: 1, thickness: 1, color: cs.outline.withValues(alpha: 0.3));
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: child,
  );
}

class _TimeTriple extends StatelessWidget {
  const _TimeTriple({
    required this.startLabel, required this.endLabel, required this.breakLabel,
    required this.startVal,   required this.endVal,   required this.breakVal,
    required this.labelColor, required this.valColor,
  });
  final String startLabel, endLabel, breakLabel;
  final String startVal,   endVal,   breakVal;
  final Color  labelColor, valColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Col(label: startLabel, value: startVal,
            labelColor: labelColor, valColor: valColor),
        const SizedBox(width: 20),
        _Col(label: endLabel, value: endVal,
            labelColor: labelColor, valColor: valColor),
        const SizedBox(width: 20),
        _Col(label: breakLabel, value: breakVal,
            labelColor: labelColor, valColor: valColor),
      ],
    );
  }
}

class _Col extends StatelessWidget {
  const _Col({required this.label, required this.value,
      required this.labelColor, required this.valColor});
  final String label, value;
  final Color  labelColor, valColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 10, color: labelColor, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: valColor)),
    ],
  );
}

class _EditableTimeRow extends StatelessWidget {
  const _EditableTimeRow({
    required this.startCtrl, required this.endCtrl, required this.breakCtrl});
  final TextEditingController startCtrl, endCtrl, breakCtrl;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _EditCol(label: 'START', ctrl: startCtrl, cs: cs),
        const SizedBox(width: 16),
        _EditCol(label: 'END', ctrl: endCtrl, cs: cs),
        const SizedBox(width: 16),
        _BreakCol(ctrl: breakCtrl, cs: cs),
      ],
    );
  }
}

class _EditCol extends StatelessWidget {
  const _EditCol({required this.label, required this.ctrl, required this.cs});
  final String            label;
  final TextEditingController ctrl;
  final ColorScheme       cs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      SizedBox(
        width: 64,
        child: TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: cs.onSurface),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    ],
  );
}

class _BreakCol extends StatelessWidget {
  const _BreakCol({required this.ctrl, required this.cs});
  final TextEditingController ctrl;
  final ColorScheme           cs;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('BREAK', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
      const SizedBox(height: 2),
      Row(children: [
        SizedBox(
          width: 32,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: cs.onSurfaceVariant),
            decoration: const InputDecoration(
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          ),
        ),
        Text(' min', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ]),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon, required this.value, required this.cs,
    this.onTap, this.muted = false,
  });
  final IconData    icon;
  final String      value;
  final ColorScheme cs;
  final VoidCallback? onTap;
  final bool        muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20,
                color: muted ? cs.onSurfaceVariant : AppColors.primary),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: muted ? cs.onSurfaceVariant : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Select Label Sheet ─────────────────────────────────────────────────────────

class _SelectLabelSheet extends StatelessWidget {
  const _SelectLabelSheet({required this.current, required this.onSelect});
  final String current;
  final ValueChanged<String> onSelect;

  static const _labels = [
    (name: 'Nachtschicht',  color: Color(0xFF90CAF9)),
    (name: 'Nachtschicht',  color: Color(0xFFF48FB1)),
    (name: 'Nachtschicht',  color: Color(0xFFFFB74D)),
    (name: 'Sachkunde',     color: Color(0xFFFFF176)),
    (name: 'Tagschicht',    color: Color(0xFF80DEEA)),
    (name: 'Unterrichtung', color: Color(0xFFA5D6A7)),
  ];

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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text(
                    'Select label',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),

          // Label list
          ...(_labels.map((l) => InkWell(
            onTap: () {
              onSelect(l.name);
              Navigator.pop(context);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: l.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(l.name, style: TextStyle(fontSize: 15, color: cs.onSurface)),
                ],
              ),
            ),
          ))),

          // Without label
          InkWell(
            onTap: () {
              onSelect('');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Without label',
                  style: TextStyle(fontSize: 15, color: AppColors.error),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
