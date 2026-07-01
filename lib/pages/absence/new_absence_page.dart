import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/absence.dart';
import 'confirmation_page.dart';

class NewAbsenceScreen extends StatefulWidget {
  const NewAbsenceScreen({super.key});

  @override
  State<NewAbsenceScreen> createState() => _NewAbsenceScreenState();
}

class _NewAbsenceScreenState extends State<NewAbsenceScreen> {
  AbsenceType? _selectedType;
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate   = _startDate.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get _totalDays => _endDate.difference(_startDate).inDays + 1;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _pickDate(bool isStart) async {
    final now   = DateTime.now();
    final init  = isStart ? _startDate : _endDate;
    final first = DateTime(now.year - 1);
    final last  = DateTime(now.year + 2, 12, 31);
    final cs    = Theme.of(context).colorScheme;

    // A fixed-height bottom-sheet Cupertino picker avoids the Material
    // showDatePicker dialog's overflow on short / web viewports.
    DateTime temp = init;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, temp),
                    child: const Text('Done',
                        style: TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: init,
                  minimumDate: first,
                  maximumDate: last,
                  onDateTimeChanged: (d) => temp = d,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        if (picked.isBefore(_startDate)) return;
        _endDate = picked;
      }
    });
  }

  void _showTypeSelector() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Select Absence Type',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
              ),
              const SizedBox(height: 8),
              ...AbsenceType.values.map((type) {
                final model = AbsenceModel(
                  id: '', type: type,
                  startDate: DateTime.now(), endDate: DateTime.now(),
                  workingDays: 1, status: AbsenceStatus.pending,
                );
                return ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: model.typeBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(model.typeIcon, color: model.typeIconColor, size: 22),
                  ),
                  title: Text(model.typeLabel,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: cs.onSurface)),
                  trailing: _selectedType == type
                      ? Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 22)
                      : null,
                  onTap: () {
                    setState(() => _selectedType = type);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedType == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final body = {
        'type':      AbsenceModel.apiTypeFor(_selectedType!),
        'startDate': _startDate.toIso8601String().split('T').first,
        'endDate':   _endDate.toIso8601String().split('T').first,
        if (_reasonCtrl.text.trim().isNotEmpty) 'reason': _reasonCtrl.text.trim(),
      };
      final resp = await ApiClient.instance.post('/api/absences', data: body);
      if (!mounted) return;

      final raw = resp is Map<String, dynamic> ? resp : <String, dynamic>{};
      final id  = ((raw['data'] is Map ? raw['data']['id'] : null) ?? raw['id'])
                      ?.toString() ?? '';

      final submitted = AbsenceModel(
        id:          id,
        type:        _selectedType!,
        startDate:   _startDate,
        endDate:     _endDate,
        workingDays: _totalDays,
        status:      AbsenceStatus.pending,
        reason:      _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
      );

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmationScreen(absence: submitted)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        surfaceTintColor:        Colors.transparent,
        scrolledUnderElevation:  0,
        elevation:               0,
        centerTitle:             true,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(fontSize: 15, color: AppColors.primary)),
        ),
        leadingWidth: 80,
        title: Text('New Absence',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type selector ─────────────────────────────────────────────
            _Label('Absence Type', cs),
            const SizedBox(height: 10),
            _Tappable(
              onTap: _showTypeSelector,
              cs: cs,
              child: Row(children: [
                if (_selectedType != null) ...[
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AbsenceModel(
                        id: '', type: _selectedType!,
                        startDate: DateTime.now(), endDate: DateTime.now(),
                        workingDays: 1, status: AbsenceStatus.pending,
                      ).typeBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AbsenceModel(
                        id: '', type: _selectedType!,
                        startDate: DateTime.now(), endDate: DateTime.now(),
                        workingDays: 1, status: AbsenceStatus.pending,
                      ).typeIcon,
                      size: 18,
                      color: AbsenceModel(
                        id: '', type: _selectedType!,
                        startDate: DateTime.now(), endDate: DateTime.now(),
                        workingDays: 1, status: AbsenceStatus.pending,
                      ).typeIconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  _selectedType == null
                      ? 'Select type...'
                      : AbsenceModel(
                          id: '', type: _selectedType!,
                          startDate: DateTime.now(), endDate: DateTime.now(),
                          workingDays: 1, status: AbsenceStatus.pending,
                        ).typeLabel,
                  style: TextStyle(
                    fontSize: 15,
                    color: _selectedType == null
                        ? cs.onSurfaceVariant
                        : cs.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(Icons.keyboard_arrow_down,
                    color: cs.onSurfaceVariant, size: 22),
              ]),
            ),
            const SizedBox(height: 22),

            // ── Date pickers ──────────────────────────────────────────────
            Row(children: [
              Expanded(child: _DateField(
                label: 'Start Date',
                value: _fmt(_startDate),
                onTap: () => _pickDate(true),
                cs: cs,
              )),
              const SizedBox(width: 12),
              Expanded(child: _DateField(
                label: 'End Date',
                value: _fmt(_endDate),
                onTap: () => _pickDate(false),
                cs: cs,
              )),
            ]),
            const SizedBox(height: 22),

            // ── Duration badge ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text('TOTAL DURATION',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: 0.5)),
                const Spacer(),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_totalDays',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w800,
                            color: cs.onSurface),
                      ),
                      TextSpan(
                        text: ' days',
                        style: TextStyle(
                            fontSize: 14, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 22),

            // ── Reason ────────────────────────────────────────────────────
            Row(children: [
              _Label('Reason', cs),
              const SizedBox(width: 8),
              Text('Optional',
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonCtrl,
              maxLines:   5,
              style:      TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText:  'Add any notes for your manager...',
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                filled:    true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Your request will be sent to your manager for approval. '
              'You will receive a notification once a decision is made.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ElevatedButton(
            onPressed: (_selectedType == null || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor:         AppColors.primary,
              disabledBackgroundColor: cs.outline.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Submit Request',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.cs);
  final String text;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface));
}

class _Tappable extends StatelessWidget {
  const _Tappable({required this.onTap, required this.cs, required this.child});
  final VoidCallback onTap;
  final ColorScheme  cs;
  final Widget       child;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label, required this.value,
    required this.onTap,  required this.cs,
  });
  final String       label, value;
  final VoidCallback onTap;
  final ColorScheme  cs;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          _Tappable(
            onTap: onTap,
            cs: cs,
            child: Row(children: [
              Icon(Icons.calendar_today_outlined,
                  size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(value,
                  style: TextStyle(fontSize: 14, color: cs.onSurface)),
            ]),
          ),
        ],
      );
}
