import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Managers/admins review shift-swap and shift-change requests here
/// (approve / reject). Employees see their own requests' statuses.
class SwapRequestsPage extends StatelessWidget {
  const SwapRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor:
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        appBar: AppBar(
          title: const Text('Requests'),
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(tabs: [Tab(text: 'Swaps'), Tab(text: 'Changes')]),
        ),
        body: const TabBarView(children: [
          _RequestList(kind: _RequestKind.swap),
          _RequestList(kind: _RequestKind.change),
        ]),
      ),
    );
  }
}

enum _RequestKind { swap, change }

class _RequestList extends StatefulWidget {
  const _RequestList({required this.kind});
  final _RequestKind kind;

  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _busyId;

  @override
  bool get wantKeepAlive => true;

  String get _basePath =>
      widget.kind == _RequestKind.swap ? 'swap-requests' : 'change-requests';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/shifts/$_basePath');
      final data = res is Map<String, dynamic>
          ? (res['data'] as List<dynamic>? ?? [])
          : (res as List<dynamic>? ?? []);
      if (!mounted) return;
      setState(() {
        _requests = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _requests = []; _loading = false; });
    }
  }

  Future<void> _review(String id, bool approve) async {
    setState(() => _busyId = id);
    try {
      await ApiClient.instance.patch('/api/shifts/$_basePath/$id', data: {'approve': approve});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Approved' : 'Rejected'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  static String _hhmm(DateTime? d) => d == null
      ? '--:--'
      : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _fmtShift(Map<String, dynamic>? shift) {
    if (shift == null) return 'Shift';
    final date  = DateTime.tryParse(shift['date'] as String? ?? '')?.toLocal();
    final start = DateTime.tryParse(shift['startTime'] as String? ?? '')?.toLocal();
    final end   = DateTime.tryParse(shift['endTime'] as String? ?? '')?.toLocal();
    final d = date == null ? '' : '${date.day}.${date.month}.${date.year}';
    return '$d · ${_hhmm(start)}–${_hhmm(end)}';
  }

  String? _detailLine(Map<String, dynamic> r) {
    if (widget.kind == _RequestKind.swap) {
      final target = r['targetUserName'] as String?;
      return target != null ? 'To: $target' : 'Release to open shifts';
    }
    final ps = DateTime.tryParse(r['proposedStartTime'] as String? ?? '')?.toLocal();
    final pe = DateTime.tryParse(r['proposedEndTime'] as String? ?? '')?.toLocal();
    if (ps == null && pe == null) return null;
    return 'Proposed: ${_hhmm(ps)}–${_hhmm(pe)}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 120),
          Center(child: Text('No requests', style: TextStyle(color: cs.onSurfaceVariant))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _card(cs, _requests[i]),
      ),
    );
  }

  Widget _card(ColorScheme cs, Map<String, dynamic> r) {
    final status = (r['status'] as String? ?? 'PENDING').toUpperCase();
    final pending = status == 'PENDING';
    final id = r['id'] as String? ?? '';
    final requester = r['requesterName'] as String? ?? 'Employee';
    final note = r['note'] as String?;
    final detail = _detailLine(r);

    Color statusColor() => switch (status) {
      'APPROVED' => AppColors.success,
      'REJECTED' => AppColors.error,
      _          => AppColors.warning,
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(requester,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor())),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_fmtShift(r['shift'] as Map<String, dynamic>?),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(detail, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"$note"',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
          ],
          if (pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busyId == id ? null : () => _review(id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busyId == id ? null : () => _review(id, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: _busyId == id
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
