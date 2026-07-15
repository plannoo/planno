import 'package:flutter/material.dart';

import '../../../core/auth/require_admin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/common/member_picker_sheet.dart';
import 'admin_availability_create_page.dart';

class AdminAvailabilitiesPage extends StatefulWidget {
  const AdminAvailabilitiesPage({super.key});

  @override
  State<AdminAvailabilitiesPage> createState() => _AdminAvailabilitiesPageState();
}

class _AdminAvailabilitiesPageState extends State<AdminAvailabilitiesPage> {
  String _userId   = '';
  String _userName = '';
  bool   _currentOnly = true;
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    requireAdmin(context);
  }

  Future<void> _load() async {
    if (_userId.isEmpty) { setState(() => _items = []); return; }
    setState(() => _loading = true);
    try {
      // "Current only" â†’ only entries from today onward.
      final q = _currentOnly
          ? '?from=${DateTime.now().toIso8601String().split('T')[0]}'
          : '';
      final data = await ApiClient.instance.get('/api/availabilities/$_userId$q');
      final raw = data is List ? data
          : ((data as Map<String, dynamic>)['data']
              ?? data['entries']
              ?? []) as List? ?? [];
      if (mounted) {
        setState(() {
          _items   = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _items = []; _loading = false; });
    }
  }

  void _pickMember() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MemberPickerSheet(
      title: 'Switch',
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<Map<String, String>>(
                  context,
                  MaterialPageRoute(builder: (_) => AdminAvailabilityCreatePage(
                    initialUserId: _userId, initialUserName: _userName,
                  )),
                );
                if (result != null) {
                  // Switch the list to the user we just created for, then reload.
                  setState(() {
                    _userId   = result['userId']   ?? _userId;
                    _userName = result['userName'] ?? _userName;
                  });
                  _load();
                }
              },
              icon: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 16, color: AppColors.primary),
              ),
              label: const Text('Add',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Availabilities',
                          style: TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    ]),
                    InkWell(
                      onTap: _pickMember,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 0, 10),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_userName.isEmpty ? 'Select member' : _userName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // all / Current only toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _hdrSeg('all',          !_currentOnly,
                              () { setState(() => _currentOnly = false); _load(); })),
                          Expanded(child: _hdrSeg('Current only', _currentOnly,
                              () { setState(() => _currentOnly = true);  _load(); })),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text('No availabilities entered',
                            style: TextStyle(color: cs.onSurface, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  itemBuilder: (_, i) => _AvailabilityRow(item: _items[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hdrSeg(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : Colors.white)),
    ),
  );
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final available = (item['type'] as String? ?? 'AVAILABLE') == 'AVAILABLE';
    final date      = (item['date'] ?? item['startDate']) as String? ?? '';
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 8, height: 36,
            decoration: BoxDecoration(
              color: available ? AppColors.success : AppColors.error,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(available ? 'Available' : 'Unavailable',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                if (date.isNotEmpty)
                  Text(date.length >= 10 ? date.substring(0, 10) : date,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (item['isWholeDay'] == true)
            Text('Whole day',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
