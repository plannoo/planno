import 'package:flutter/material.dart';

import '../../../core/auth/require_admin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/member_picker_sheet.dart';

class AdminEntitlementPage extends StatefulWidget {
  const AdminEntitlementPage({super.key});

  @override
  State<AdminEntitlementPage> createState() => _AdminEntitlementPageState();
}

class _AdminEntitlementPageState extends State<AdminEntitlementPage> {
  int      _year       = DateTime.now().year;
  String   _userId     = '';
  String   _userName   = '';
  int?     _entitled, _requested, _accepted;
  bool     _loading    = false;

  @override
  void initState() {
    super.initState();
    requireAdmin(context);
  }

  Future<void> _load() async {
    if (_userId.isEmpty) return;
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance
          .get('/api/vacation-entitlements/$_userId?year=$_year');
      final wrap = (data is Map<String, dynamic>) ? data : <String, dynamic>{};
      final body = (wrap['data'] ?? wrap) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _entitled  = (body['entitlementDays'] as num?)?.toInt();
          _requested = (body['requested']       as num?)?.toInt();
          _accepted  = (body['accepted']        as num?)?.toInt();
          _serverRemaining = (body['remaining'] as num?)?.toInt();
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _entitled = null; _requested = null; _accepted = null; _loading = false;
        });
      }
    }
  }

  int? _serverRemaining;
  int? get _remaining {
    if (_serverRemaining != null) return _serverRemaining;
    if (_entitled == null || _accepted == null) return null;
    return _entitled! - _accepted!;
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
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Entitlement',
                            style: TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        MemberChip(name: _userName, onTap: _pickMember),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
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
                              onPressed: () { setState(() => _year--); _load(); },
                            ),
                            Container(width: 1, height: 24, color: Colors.white60),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              constraints: const BoxConstraints(),
                              onPressed: () { setState(() => _year++); _load(); },
                            ),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        Text('$_year',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                _row(cs, 'Entitlement',          _entitled),
                                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                                _row(cs, 'Requested',            _requested),
                                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                                _row(cs, 'Accepted',             _accepted),
                                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                                _row(cs, 'Remaining Entitlement',_remaining),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('in days',
                              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(ColorScheme cs, String label, int? value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    child: Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
        ),
        Text(value?.toString() ?? '-',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ],
    ),
  );
}
