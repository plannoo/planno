import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

class BirthDatesPage extends StatefulWidget {
  const BirthDatesPage({super.key});

  @override
  State<BirthDatesPage> createState() => _BirthDatesPageState();
}

class _BirthDatesPageState extends State<BirthDatesPage> {
  List<_Birthday> _soon  = [];
  List<_Birthday> _later = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance
          .get('/api/dashboard/birthdays') as Map<String, dynamic>;
      if (!mounted) return;
      final soon  = (data['soon']  as List<dynamic>? ?? []).map(_parse).toList();
      final later = (data['later'] as List<dynamic>? ?? []).map(_parse).toList();
      setState(() { _soon = soon; _later = later; });
    } catch (_) {
      if (mounted) setState(() { _soon = []; _later = []; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _Birthday _parse(dynamic e) {
    final m = e as Map<String, dynamic>;
    return _Birthday(
      name: '${m['lastName'] ?? ''}, ${m['firstName'] ?? ''}'.trim().replaceAll(RegExp(r'^,\s*'), ''),
      dateLabel: m['dateLabel'] as String? ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Birth dates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: (_soon.isEmpty && _later.isEmpty)
                  ? Center(
                      child: Text('No upcoming birthdays',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15)))
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        if (_soon.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
                            child: Text(
                              'Soon',
                              style: TextStyle(
                                fontSize: 14, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400),
                            ),
                          ),
                          Container(
                            color: cs.surface,
                            child: Column(
                              children: [
                                for (int i = 0; i < _soon.length; i++) ...[
                                  if (i > 0)
                                    Divider(height: 1, indent: 16,
                                        color: cs.outline.withValues(alpha: 0.2)),
                                  _BirthdayRow(birthday: _soon[i]),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (_later.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8, top: 4),
                            child: Text(
                              'Later',
                              style: TextStyle(
                                fontSize: 14, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400),
                            ),
                          ),
                          Container(
                            color: cs.surface,
                            child: Column(
                              children: [
                                for (int i = 0; i < _later.length; i++) ...[
                                  if (i > 0)
                                    Divider(height: 1, indent: 16,
                                        color: cs.outline.withValues(alpha: 0.2)),
                                  _BirthdayRow(birthday: _later[i]),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }
}

class _Birthday {
  const _Birthday({required this.name, required this.dateLabel});
  final String name;
  final String dateLabel;
}

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.birthday});
  final _Birthday birthday;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(birthday.name,
                style: TextStyle(fontSize: 15, color: cs.onSurface)),
          ),
          Text(birthday.dateLabel,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
