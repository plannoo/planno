import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/require_admin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_absence_edit_page.dart';

class AdminAbsencesPage extends StatefulWidget {
  const AdminAbsencesPage({super.key});

  @override
  State<AdminAbsencesPage> createState() => _AdminAbsencesPageState();
}

class _AdminAbsencesPageState extends State<AdminAbsencesPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _yearView  = false;
  List<_Entry> _entries = [];
  bool _loading = true;
  String? _employeeFilter; // null = all
  String? _typeFilter;     // null = all

  @override
  void initState() {
    super.initState();
    if (!requireAdmin(context)) return;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final from = _yearView
          ? DateTime(_month.year, 1, 1)
          : DateTime(_month.year, _month.month, 1);
      final to   = _yearView
          ? DateTime(_month.year, 12, 31)
          : DateTime(_month.year, _month.month + 1, 0);
      String iso(DateTime d) => d.toIso8601String().split('T')[0];
      final data = await ApiClient.instance.get(
          '/api/absences?from=${iso(from)}&to=${iso(to)}&scope=org');
      final list = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _entries = List<Map<String, dynamic>>.from(list)
              .map(_Entry.fromJson)
              .where((e) =>
                  (_employeeFilter == null || e.name == _employeeFilter) &&
                  (_typeFilter     == null || e.type == _typeFilter))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _entries = []; _loading = false; });
    }
  }

  void _prev() {
    setState(() => _month = _yearView
        ? DateTime(_month.year - 1, _month.month, 1)
        : DateTime(_month.year, _month.month - 1, 1));
    _load();
  }
  void _next() {
    setState(() => _month = _yearView
        ? DateTime(_month.year + 1, _month.month, 1)
        : DateTime(_month.year, _month.month + 1, 1));
    _load();
  }

  Future<void> _showEmployeeFilter() async {
    try {
      final data = await ApiClient.instance.get('/api/users');
      final raw  = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final names = raw
          .map((u) {
            final m = u as Map<String, dynamic>;
            return ('${m['firstName'] ?? ''} ${m['lastName'] ?? ''}').trim();
          })
          .where((n) => n.isNotEmpty)
          .toList()
        ..sort();
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SwitchSheet(
          title: 'Switch',
          showSearch: true,
          items: [_SwitchItem(label: 'All employees'), ...names.map((n) => _SwitchItem(label: n))],
          selected: _employeeFilter ?? 'All employees',
          onSelect: (label) => setState(() {
            _employeeFilter = label == 'All employees' ? null : label;
            _load();
          }),
        ),
      );
    } catch (_) {}
  }

  void _showTypeFilter() {
    final types = [
      _SwitchItem(label: 'Krankheit',                value: 'SICK',     dot: Color(0xFF4CAF50)),
      _SwitchItem(label: 'Qualifikation',            value: 'TRAINING', dot: Color(0xFF8BC34A)),
      _SwitchItem(label: 'Stand by/ frei',           value: 'STANDBY',  dot: Color(0xFFFFC107)),
      _SwitchItem(label: 'Überstundenausgleich',     value: 'OVERTIME', dot: Color(0xFFE91E63)),
      _SwitchItem(label: 'Unentschuldigte Abwesenheit', value: 'UNEXCUSED', dot: Color(0xFFE53935)),
      _SwitchItem(label: 'Urlaub',                   value: 'VACATION', dot: Color(0xFF0EA5E9)),
      _SwitchItem(label: 'Wunschfrei',               value: 'PREFERRED_OFF', dot: Color(0xFFE91E63)),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SwitchSheet(
        title: 'Switch',
        items: [_SwitchItem(label: 'All types'), ...types],
        selected: _typeFilter ?? 'All types',
        onSelect: (label) => setState(() {
          _typeFilter = label == 'All types' ? null
              : types.firstWhere((t) => t.label == label,
                  orElse: () => types.first).value;
          _load();
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final saved = await Navigator.push<bool>(context,
                    MaterialPageRoute(builder: (_) => const AdminAbsenceEditPage()));
                if (saved == true) _load();
              },
              icon: Container(
                width: 22, height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 16, color: AppColors.primary),
              ),
              label: const Text('Add absence entry',
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
          // ── Blue header ─────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Absences',
                            style: TextStyle(
                                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Prev / next
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                                onPressed: _prev,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                constraints: const BoxConstraints(),
                              ),
                              Container(width: 1, height: 24, color: Colors.white60),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                                onPressed: _next,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text.rich(TextSpan(children: [
                          if (!_yearView)
                            TextSpan(text: DateFormat('MMMM', Intl.defaultLocale ?? 'en').format(_month),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                          TextSpan(text: _yearView ? '${_month.year}' : ' ${_month.year}',
                              style: TextStyle(
                                  color: _yearView ? Colors.white : Colors.white70,
                                  fontSize: _yearView ? 20 : 15,
                                  fontWeight: _yearView ? FontWeight.w600 : FontWeight.w400)),
                        ])),
                        const Spacer(),
                        // Month/Jahr toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              _toggleBtn('Month', !_yearView, () { setState(() => _yearView = false); _load(); }),
                              _toggleBtn('Jahr',  _yearView,  () { setState(() => _yearView = true);  _load(); }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _showEmployeeFilter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(_employeeFilter ?? 'Employee',
                                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showTypeFilter,
                          child: Icon(Icons.filter_list,
                              color: _typeFilter == null ? Colors.white70 : Colors.white,
                              size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(child: Text('No absences this month',
                        style: TextStyle(color: cs.onSurfaceVariant)))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          itemCount: _entries.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                          itemBuilder: (_, i) => InkWell(
                            onTap: () async {
                              final saved = await Navigator.push<bool>(context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminAbsenceEditPage(entry: _entries[i].toMap()),
                                  ));
                              if (saved == true) _load();
                            },
                            child: _AbsenceRow(entry: _entries[i], month: _yearView
                                ? DateTime(_month.year, 1, 1) : _month, yearView: _yearView),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : Colors.white70)),
    ),
  );
}

class _Entry {
  _Entry({required this.id, required this.name, required this.start, required this.end,
      required this.type, this.avatarUrl, this.comment});
  final String id;
  final String name;
  final DateTime start, end;
  final String type;
  final String? avatarUrl;
  final String? comment;

  factory _Entry.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    final firstName = user?['firstName'] ?? j['firstName'] ?? '';
    final lastName  = user?['lastName']  ?? j['lastName']  ?? '';
    final avatar    = user?['avatarUrl'] as String? ?? j['avatarUrl'] as String?;
    return _Entry(
      id:    j['id'] as String? ?? '',
      name: '$firstName $lastName'.trim(),
      start: DateTime.parse(j['startDate'] as String),
      end:   DateTime.parse(j['endDate']   as String),
      type:  (j['type'] as String?) ?? 'OTHER',
      avatarUrl: avatar,
      comment: j['comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'type': type,
    'start': start.toIso8601String(), 'end': end.toIso8601String(),
    'comment': comment,
  };
}

// ── Switch sheet (filter picker) ──────────────────────────────────────────────

class _SwitchItem {
  _SwitchItem({required this.label, this.value, this.dot});
  final String label;
  final String? value;
  final Color?  dot;
}

class _SwitchSheet extends StatefulWidget {
  const _SwitchSheet({
    required this.title, required this.items, required this.selected,
    required this.onSelect, this.showSearch = false,
  });
  final String title;
  final List<_SwitchItem> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool showSearch;

  @override
  State<_SwitchSheet> createState() => _SwitchSheetState();
}

class _SwitchSheetState extends State<_SwitchSheet> {
  late List<_SwitchItem> _filtered;
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
      initialChildSize: 0.8,
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
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            if (widget.showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    onTap: () { widget.onSelect(item.label); Navigator.pop(context); },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          if (item.dot != null) ...[
                            Container(
                              width: 12, height: 12,
                              decoration: BoxDecoration(
                                color: item.dot,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 14),
                          ],
                          Text(item.label,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: item.label == widget.selected
                                      ? AppColors.primary : cs.onSurface,
                                  fontWeight: item.label == widget.selected
                                      ? FontWeight.w600 : FontWeight.w400)),
                        ],
                      ),
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

class _AbsenceRow extends StatelessWidget {
  const _AbsenceRow({required this.entry, required this.month, this.yearView = false});
  final _Entry entry;
  final DateTime month;
  final bool yearView;

  Color _typeColor(String t) {
    switch (t) {
      case 'VACATION':  return const Color(0xFFFFA726); // orange
      case 'SICK':      return const Color(0xFFE91E63); // pink
      case 'STANDBY':   return const Color(0xFFFFC107); // yellow
      default:          return const Color(0xFF9E9E9E);
    }
  }

  String _dateLabel() {
    String ds(DateTime d) =>
        '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}';
    final sameDay = entry.start.year == entry.end.year &&
                    entry.start.month == entry.end.month &&
                    entry.start.day == entry.end.day;
    return sameDay ? ds(entry.start) : '${ds(entry.start)} - ${ds(entry.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = _typeColor(entry.type);
    final double left, width;
    if (yearView) {
      final yearStart = DateTime(month.year, 1, 1);
      final yearEnd   = DateTime(month.year, 12, 31);
      final yearDays  = yearEnd.difference(yearStart).inDays + 1;
      final s = entry.start.year == month.year
          ? entry.start.difference(yearStart).inDays : 0;
      final e = entry.end.year == month.year
          ? entry.end.difference(yearStart).inDays   : yearDays - 1;
      left  = s / yearDays;
      width = (e - s + 1) / yearDays;
    } else {
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final startDay = entry.start.month == month.month ? entry.start.day : 1;
      final endDay   = entry.end.month == month.month   ? entry.end.day : daysInMonth;
      left  = (startDay - 1) / daysInMonth;
      width = (endDay - startDay + 1) / daysInMonth;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (entry.avatarUrl != null) ...[
                CircleAvatar(radius: 11, backgroundImage: NetworkImage(entry.avatarUrl!)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(entry.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: cs.onSurface)),
              ),
              Text(_dateLabel(),
                  style: TextStyle(fontSize: 13, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (_, c) {
            return Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Positioned(
                  left: c.maxWidth * left,
                  child: Container(
                    width:  (c.maxWidth * width).clamp(8, c.maxWidth),
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
