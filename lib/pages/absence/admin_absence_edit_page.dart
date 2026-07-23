import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

const _typeLabels = {
  'SICK':           'Krankheit',
  'TRAINING':       'Qualifikation',
  'STANDBY':        'Stand by/ frei',
  'OVERTIME':       'Überstundenausgleich',
  'UNEXCUSED':      'Unentschuldigte Abwesenheit',
  'VACATION':       'Urlaub',
  'PREFERRED_OFF':  'Wunschfrei',
};

class AdminAbsenceEditPage extends StatefulWidget {
  const AdminAbsenceEditPage({super.key, this.entry});
  final Map<String, dynamic>? entry; // null = new

  @override
  State<AdminAbsenceEditPage> createState() => _AdminAbsenceEditPageState();
}

class _AdminAbsenceEditPageState extends State<AdminAbsenceEditPage> {
  String? _id;
  String  _name    = '';
  String  _userId  = '';
  String? _type;
  DateTime? _from;
  DateTime? _to;
  String _comment  = '';
  String?       _fileName;
  PlatformFile? _pickedFile;
  bool _saving     = false;

  bool get _isEdit => widget.entry != null;
  bool get _canSave =>
      _userId.isNotEmpty && _type != null && _from != null && _to != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _id      = e['id']      as String?;
      _name    = e['name']    as String? ?? '';
      _userId  = e['userId']  as String? ?? '';
      _type    = e['type']    as String?;
      _from    = (e['start'] != null) ? DateTime.parse(e['start'] as String) : null;
      _to      = (e['end']   != null) ? DateTime.parse(e['end']   as String) : null;
      _comment = e['comment'] as String? ?? '';
    }
  }

  int get _effectiveDays {
    if (_from == null || _to == null) return 0;
    return _to!.difference(_from!).inDays + 1;
  }

  String _fmtDate(DateTime? d) => d == null
      ? '' : '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}';

  Future<void> _pickDate(bool isFrom) async {
    DateTime picked = (isFrom ? _from : _to) ?? DateTime.now();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 240,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                onDateTimeChanged: (dt) => picked = dt,
              ),
            ),
            CupertinoButton(
              child: const Text('Accept', style: TextStyle(color: AppColors.primary)),
              onPressed: () { setState(() {
                if (isFrom) {
                  _from = picked;
                  if (_to != null && _to!.isBefore(picked)) _to = picked;
                } else { _to = picked; }
              }); Navigator.pop(context); },
            ),
            CupertinoButton(
              child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickEmployee() async {
    try {
      final data = await ApiClient.instance.get('/api/users');
      final raw  = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final users = List<Map<String, dynamic>>.from(raw);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _PickerSheet(
          title: 'Employees',
          items: users.map((u) => _PickerItem(
            id:    u['id'] as String? ?? '',
            label: ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim(),
          )).where((i) => i.label.isNotEmpty).toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
          onSelect: (id, label) => setState(() {
            _userId = id; _name = label;
          }),
        ),
      );
    } catch (_) {}
  }

  void _pickType() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Type',
        items: _typeLabels.entries
            .map((e) => _PickerItem(id: e.key, label: e.value))
            .toList(),
        onSelect: (id, _) => setState(() => _type = id),
      ),
    );
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(withData: true);
    if (r != null && mounted) {
      setState(() {
        _pickedFile = r.files.single;
        _fileName   = _pickedFile!.name;
      });
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final body = {
        'userId':    _userId,
        'type':      _type,
        'startDate': _from!.toIso8601String().split('T')[0],
        'endDate':   _to!  .toIso8601String().split('T')[0],
        if (_comment.isNotEmpty) 'comment': _comment,
      };
      String savedId;
      if (_isEdit && _id != null && _id!.isNotEmpty) {
        await ApiClient.instance.put('/api/absences/$_id', data: body);
        savedId = _id!;
      } else {
        final resp = await ApiClient.instance.post('/api/absences', data: body);
        if (resp is Map<String, dynamic>) {
          final inner = resp['data'];
          savedId = (resp['id'] ?? (inner is Map ? inner['id'] : null))
              ?.toString() ?? '';
        } else {
          savedId = '';
        }
      }
      if (_pickedFile != null && savedId.isNotEmpty) {
        final file = _pickedFile!;
        final multipart = file.path != null
            ? await MultipartFile.fromFile(file.path!, filename: file.name)
            : MultipartFile.fromBytes(file.bytes ?? [], filename: file.name);
        final form = FormData.fromMap({'file': multipart});
        await ApiClient.instance.post('/api/absences/$savedId/attachments',
            data: form);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _delete() async {
    if (_id == null || _id!.isEmpty) return;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete absence?'),
        actions: [
          CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiClient.instance.delete('/api/absences/$_id');
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      // A MANAGER can now be refused here ("Managers can manage absences" off).
      // Swallowing it left the page open with a dead button, which reads as a
      // frozen app rather than a policy decision.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: _isEdit
              ? Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _delete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Delete',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _canSave && !_saving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canSave ? AppColors.primary : Colors.grey,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ])
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSave && !_saving ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSave ? AppColors.primary : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Absence',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
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
                  // Employee
                  InkWell(
                    onTap: _pickEmployee,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 22,
                              color: _name.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(_name.isEmpty ? (_isEdit ? '' : 'Employees') : _name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16,
                                    color: _name.isEmpty ? cs.onSurfaceVariant : cs.onSurface)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 52, color: cs.outline.withValues(alpha: 0.2)),

                  // Type
                  InkWell(
                    onTap: _pickType,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.label_outline,
                              size: 22,
                              color: _type == null ? cs.onSurfaceVariant : AppColors.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(_type == null ? 'Type' : (_typeLabels[_type!] ?? _type!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16,
                                    color: _type == null ? cs.onSurfaceVariant : cs.onSurface)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 52, color: cs.outline.withValues(alpha: 0.2)),

                  // From
                  InkWell(
                    onTap: () => _pickDate(true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 22,
                              color: _from == null ? cs.onSurfaceVariant : AppColors.primary),
                          const SizedBox(width: 14),
                          Text('from  ',
                              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
                          Text(_fmtDate(_from),
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600, color: cs.onSurface)),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 52, color: cs.outline.withValues(alpha: 0.2)),

                  // To
                  InkWell(
                    onTap: () => _pickDate(false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined,
                              size: 22,
                              color: _to == null ? cs.onSurfaceVariant : AppColors.primary),
                          const SizedBox(width: 14),
                          Text('to  ',
                              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
                          Text(_fmtDate(_to),
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600, color: cs.onSurface)),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),

                  // Effective days (only when both dates picked)
                  if (_from != null && _to != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(width: 36),
                          Text('Effective days: ',
                              style: TextStyle(fontSize: 16, color: cs.onSurface)),
                          Text('$_effectiveDays',
                              style: const TextStyle(
                                  fontSize: 17,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  ],

                  // Comment
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 22,
                            color: _comment.isEmpty ? cs.onSurfaceVariant : AppColors.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(text: _comment)
                              ..selection = TextSelection.collapsed(offset: _comment.length),
                            onChanged: (v) => _comment = v,
                            style: TextStyle(fontSize: 16, color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Comment',
                              hintStyle: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
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

                  // Upload file
                  InkWell(
                    onTap: _pickFile,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file_outlined,
                              size: 22, color: cs.onSurfaceVariant),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(_fileName ?? 'Upload file',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 16, color: cs.onSurface)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Picker sheet (employee / type) ────────────────────────────────────────────

class _PickerItem {
  _PickerItem({required this.id, required this.label});
  final String id, label;
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({required this.title, required this.items, required this.onSelect});
  final String title;
  final List<_PickerItem> items;
  final void Function(String id, String label) onSelect;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late List<_PickerItem> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() => _filtered = widget.items
          .where((i) => i.label.toLowerCase().contains(q)).toList());
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
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
                  Expanded(
                    child: Text(widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                itemCount: _filtered.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  return InkWell(
                    onTap: () { widget.onSelect(item.id, item.label); Navigator.pop(context); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Text(item.label,
                          style: TextStyle(fontSize: 15, color: cs.onSurface)),
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
