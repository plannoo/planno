import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/master_data_labels.dart';
import '../../providers/auth_provider.dart';
import 'employee_documents_page.dart';

class EmployeeDetailPage extends StatefulWidget {
  const EmployeeDetailPage({super.key, required this.userId, required this.name});
  final String userId;
  final String name;

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  Map<String, dynamic>? _user;
  // Master data fields: [{ fieldId, label, type, isLocked, value }]
  List<Map<String, dynamic>> _masterData = [];
  bool _loading = true;
  bool _editing = false;
  bool _saving  = false;
  // Field controllers keyed by fieldId — created when entering edit mode.
  final Map<String, TextEditingController> _ctrls = {};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() {
    for (final c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  // _editing toggles swap entire widget subtrees under the button/fields the
  // user just clicked (OutlinedButton "Edit" -> ElevatedButton "Save" +
  // GestureDetector "Close"; Text -> TextField). Doing that swap synchronously
  // inside the tap callback races Flutter web's mouse tracker, which is still
  // mid-dispatch of the same pointer event over the widget being replaced —
  // triggering an "Assertion failed" in mouse_tracker.dart. Deferring the
  // setState to the next frame lets the pointer event finish first.
  void _setEditing(bool value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _editing = value);
    });
  }

  void _enterEdit() {
    for (final f in _masterData) {
      if (f['isLocked'] == true) continue;
      final id = f['fieldId'] as String;
      _ctrls[id] = TextEditingController(text: f['value'] as String? ?? '');
    }
    _setEditing(true);
  }

  void _exitEdit({bool save = false}) async {
    if (!save) {
      for (final c in _ctrls.values) { c.dispose(); }
      _ctrls.clear();
      _setEditing(false);
      return;
    }
    setState(() => _saving = true);
    try {
      // Send every editable field including blanks so a cleared field is unset.
      final values = _ctrls.entries
          .map((e) => {'fieldId': e.key, 'value': e.value.text.trim()})
          .toList();
      final res = await ApiClient.instance.put(
          '/api/master-data/users/${widget.userId}', data: {'values': values});
      final wrap = (res is Map<String, dynamic>) ? res : <String, dynamic>{};
      final updated = (wrap['data'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      for (final c in _ctrls.values) { c.dispose(); }
      _ctrls.clear();
      if (mounted) {
        setState(() {
          if (updated != null) _masterData = updated;
          _saving = false;
        });
        _setEditing(false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/users/${widget.userId}'),
        ApiClient.instance.get('/api/master-data/users/${widget.userId}'),
      ]);
      final uWrap = (results[0] is Map<String, dynamic>)
          ? results[0] as Map<String, dynamic> : <String, dynamic>{};
      final user = (uWrap['data'] ?? uWrap) as Map<String, dynamic>;
      final mdWrap = (results[1] is Map<String, dynamic>)
          ? results[1] as Map<String, dynamic> : <String, dynamic>{};
      final md = (mdWrap['data'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      if (mounted) setState(() { _user = user; _masterData = md; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _user = {}; _masterData = []; _loading = false; });
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':                return const Color(0xFF4CAF50);
      case 'geschäftsführer':      return const Color(0xFFE53935);
      case 'manager':              return const Color(0xFFFF9800);
      case 'sachkunde':            return const Color(0xFF06B6D4);
      case 'schichtleiter':        return const Color(0xFF8BC34A);
      case 'sicherheitspersonal':  return const Color(0xFFE91E63);
      default:                     return AppColors.primary;
    }
  }

  /// Admin-only: pick a new account role for this employee and PATCH it.
  Future<void> _changeRole() async {
    const roles = ['EMPLOYEE', 'MANAGER', 'ADMIN'];
    final current = (_user?['role'] as String?)?.toUpperCase();
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Text('Change role',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 8),
              for (final r in roles)
                ListTile(
                  leading: Icon(
                      r == current ? Icons.radio_button_checked
                                   : Icons.radio_button_unchecked,
                      color: AppColors.primary),
                  title: Text(r, style: TextStyle(color: cs.onSurface)),
                  onTap: () => Navigator.pop(ctx, r),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || picked == current) return;
    try {
      await ApiClient.instance
          .patch('/api/users/${widget.userId}', data: {'role': picked});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Role updated to $picked'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final u  = _user ?? {};
    final roleName = u['role'] as String? ?? 'Sicherheitspersonal';
    final skills   = (u['skills'] as List<dynamic>?)?.cast<String>() ?? const ['Unterrichtung'];

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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(widget.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Documents card
                        _Card(
                          child: InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => EmployeeDocumentsPage(
                                  userId: widget.userId, name: widget.name),
                            )),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file_outlined,
                                      color: AppColors.primary, size: 24),
                                  const SizedBox(width: 14),
                                  Text('Documents',
                                      style: TextStyle(
                                          fontSize: 16, color: cs.onSurface)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Roles card
                        _Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Roles',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _changeRole, // admin: tap to change role
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 14, height: 14,
                                          decoration: BoxDecoration(
                                            color: _roleColor(roleName),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(roleName,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 16, color: cs.onSurface)),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.edit_outlined,
                                            size: 15, color: cs.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Permissions card — only for manager users, visible to admins
                        if (context.select<AuthProvider, bool>((a) => a.isSuperAdmin) &&
                            (u['role'] as String?)?.toUpperCase() == 'MANAGER')
                          _ManagerPermissionsCard(userId: widget.userId),
                        const SizedBox(height: 10),
                        // Skill card
                        _Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Skill',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                for (final s in skills)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('•  ',
                                            style: TextStyle(fontSize: 16, color: cs.onSurface)),
                                        Expanded(
                                          child: Text(s,
                                              style: TextStyle(
                                                  fontSize: 16, color: cs.onSurface)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Master data
                        Row(
                          children: [
                            Text('Master data',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface)),
                            const Spacer(),
                            if (_editing) ...[
                              ElevatedButton.icon(
                                onPressed: _saving ? null : () => _exitEdit(save: true),
                                icon: _saving
                                    ? const SizedBox(width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.save_outlined,
                                        size: 16, color: Colors.white),
                                label: const Text('Save',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.w500)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  elevation: 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _saving ? null : () => _exitEdit(),
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                            ] else
                              OutlinedButton.icon(
                                onPressed: _enterEdit,
                                icon: const Icon(Icons.edit_outlined,
                                    size: 16, color: AppColors.primary),
                                label: const Text('Edit',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_masterData.isEmpty)
                          Text('No master data',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14))
                        else
                          for (int i = 0; i < _masterData.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _field(cs, _masterData[i]),
                          ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _field(ColorScheme cs, Map<String, dynamic> f) {
    final id       = f['fieldId'] as String;
    final label    = localizedMasterDataLabel(context, f['label'] as String? ?? '');
    final isLocked = f['isLocked'] == true;
    final value    = f['value']   as String?;
    final editable = _editing && !isLocked && _ctrls.containsKey(id);
    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color: editable ? AppColors.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            if (editable)
              TextField(
                controller: _ctrls[id],
                style: TextStyle(fontSize: 15, color: cs.onSurface),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            else
              Text((value == null || value.isEmpty) ? '-' : value,
                  style: TextStyle(fontSize: 15, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: child,
    );
  }
}

// ── Manager permissions card ──────────────────────────────────────────────────

class _ManagerPermissionsCard extends StatefulWidget {
  const _ManagerPermissionsCard({required this.userId});
  final String userId;

  @override
  State<_ManagerPermissionsCard> createState() => _ManagerPermissionsCardState();
}

class _ManagerPermissionsCardState extends State<_ManagerPermissionsCard> {
  List<Map<String, dynamic>> _permissions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/api/users/${widget.userId}/permissions');
      final wrap = (res is Map<String, dynamic>) ? res : <String, dynamic>{};
      final data = (wrap['data'] as Map<String, dynamic>?) ?? {};
      final perms = (data['permissions'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
      if (mounted) setState(() { _permissions = perms; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManagerPermissionsSheet(
        userId: widget.userId,
        permissions: List.from(_permissions),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final grantedCount = _permissions.where((p) => p['granted'] == true).length;
    final total        = _permissions.length;

    return _Card(
      child: InkWell(
        onTap: _loading ? null : _openSheet,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Row(
            children: [
              const Icon(Icons.tune_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manager permissions',
                        style: TextStyle(fontSize: 15, color: cs.onSurface,
                            fontWeight: FontWeight.w500)),
                    if (!_loading)
                      Text('$grantedCount of $total enabled',
                          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Manager permissions sheet ─────────────────────────────────────────────────

class _ManagerPermissionsSheet extends StatefulWidget {
  const _ManagerPermissionsSheet({required this.userId, required this.permissions});
  final String userId;
  final List<Map<String, dynamic>> permissions;

  @override
  State<_ManagerPermissionsSheet> createState() => _ManagerPermissionsSheetState();
}

class _ManagerPermissionsSheetState extends State<_ManagerPermissionsSheet> {
  late List<Map<String, dynamic>> _perms;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _perms = widget.permissions.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final denied = _perms
          .where((p) => p['granted'] == false)
          .map((p) => p['key'] as String)
          .toList();
      await ApiClient.instance.put(
        '/api/users/${widget.userId}/permissions',
        data: {'deniedPermissions': denied},
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Manager permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _perms.map((p) {
                  return SwitchListTile(
                    title: Text(p['label'] as String,
                        style: TextStyle(fontSize: 15, color: cs.onSurface)),
                    value: p['granted'] == true,
                    onChanged: (v) => setState(() => p['granted'] = v),
                    activeThumbColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Save',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
