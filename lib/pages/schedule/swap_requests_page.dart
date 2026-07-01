import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

/// Managers/admins review shift-swap requests here (approve / reject).
/// Employees see their own requests' statuses.
class SwapRequestsPage extends StatefulWidget {
  const SwapRequestsPage({super.key});

  @override
  State<SwapRequestsPage> createState() => _SwapRequestsPageState();
}

class _SwapRequestsPageState extends State<SwapRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/api/shifts/swap-requests');
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
      await ApiClient.instance
          .patch('/api/shifts/swap-requests/$id', data: {'approve': approve});
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approve ? 'Swap approved' : 'Swap rejected'),
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

  String _fmtShift(Map<String, dynamic>? shift) {
    if (shift == null) return 'Shift';
    final date  = DateTime.tryParse(shift['date'] as String? ?? '')?.toLocal();
    final start = DateTime.tryParse(shift['startTime'] as String? ?? '')?.toLocal();
    final end   = DateTime.tryParse(shift['endTime'] as String? ?? '')?.toLocal();
    String hhmm(DateTime? d) => d == null
        ? '--:--'
        : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final d = date == null ? '' : '${date.day}.${date.month}.${date.year}';
    return '$d Â· ${hhmm(start)}â€“${hhmm(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      appBar: AppBar(title: const Text('Swap requests'), surfaceTintColor: Colors.transparent),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Text('No swap requests',
                  style: TextStyle(color: cs.onSurfaceVariant)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _card(cs, _requests[i]),
                  ),
                ),
    );
  }

  Widget _card(ColorScheme cs, Map<String, dynamic> r) {
    final status = (r['status'] as String? ?? 'PENDING').toUpperCase();
    final pending = status == 'PENDING';
    final id = r['id'] as String? ?? '';
    final requester = r['requesterName'] as String? ?? 'Employee';
    final target = r['targetUserName'] as String?;
    final note = r['note'] as String?;

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
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: statusColor())),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_fmtShift(r['shift'] as Map<String, dynamic>?),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(target != null ? 'To: $target' : 'Release to open shifts',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('"$note"',
                style: TextStyle(
                    fontSize: 13, fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant)),
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
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
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
