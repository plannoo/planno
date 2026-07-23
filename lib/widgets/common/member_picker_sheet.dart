import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/user_search.dart';
import '../../core/theme/app_colors.dart';

/// "Select members" bottom sheet — server-side searched & paginated against
/// `/api/users`. Returns `{ id, name }` via [onSelect].
class MemberPickerSheet extends StatefulWidget {
  const MemberPickerSheet({
    super.key,
    required this.onSelect,
    this.title = 'Select members',
  });

  final void Function(String id, String name) onSelect;
  final String title;

  @override
  State<MemberPickerSheet> createState() => _MemberPickerSheetState();
}

class _MemberPickerSheetState extends State<MemberPickerSheet> {
  final _pager = UserSearchPager();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = true;

  List<Map<String, dynamic>> get _filtered => _pager.users;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _load(reset: true, query: _searchCtrl.text.trim());
    });
  }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        _pager.hasMore && !_pager.isLoading) {
      _load();
    }
    return false;
  }

  Future<void> _load({bool reset = false, String? query}) async {
    if (reset) setState(() => _loading = true);
    await _pager.load(reset: reset, query: query);
    if (mounted) setState(() => _loading = false);
  }

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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(child: Text('No employees found',
                          style: TextStyle(color: cs.onSurfaceVariant)))
                      : NotificationListener<ScrollNotification>(
                          onNotification: _onScroll,
                          child: ListView.separated(
                            controller: scrollCtrl,
                            itemCount: _filtered.length + (_pager.hasMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                            itemBuilder: (_, i) {
                              if (i >= _filtered.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                                );
                              }
                              final u = _filtered[i];
                              final id = u['id'] as String? ?? '';
                              final name = ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim();
                              return InkWell(
                                onTap: () { widget.onSelect(id, name); Navigator.pop(context); },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Text(name,
                                      style: TextStyle(fontSize: 15, color: cs.onSurface)),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }
}

/// Multi-select member sheet (server-searched + paginated). Returns the chosen
/// `{id, name}` pairs via [onDone] when the user taps "Done".
class MultiMemberPickerSheet extends StatefulWidget {
  const MultiMemberPickerSheet({
    super.key,
    required this.onDone,
    this.initialSelectedIds = const {},
    this.title = 'Select employees',
  });
  final void Function(List<({String id, String name})>) onDone;
  final Set<String> initialSelectedIds;
  final String title;

  @override
  State<MultiMemberPickerSheet> createState() => _MultiMemberPickerSheetState();
}

class _MultiMemberPickerSheetState extends State<MultiMemberPickerSheet> {
  final _pager = UserSearchPager();
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  late final Set<String> _selected = {...widget.initialSelectedIds};
  final Map<String, String> _names = {};

  List<Map<String, dynamic>> get _filtered => _pager.users;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300),
          () => _load(reset: true, query: _searchCtrl.text.trim()));
    });
  }

  @override
  void dispose() { _debounce?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        _pager.hasMore && !_pager.isLoading) { _load(); }
    return false;
  }

  Future<void> _load({bool reset = false, String? query}) async {
    if (reset) setState(() => _loading = true);
    await _pager.load(reset: reset, query: query);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85, minChildSize: 0.4, maxChildSize: 0.95, expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  GestureDetector(
                    onTap: () {
                      widget.onDone(_selected
                          .map((id) => (id: id, name: _names[id] ?? '')).toList());
                      Navigator.pop(context);
                    },
                    child: const Text('Done',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
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
                      borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : NotificationListener<ScrollNotification>(
                      onNotification: _onScroll,
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: _filtered.length + (_pager.hasMore ? 1 : 0),
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                        itemBuilder: (_, i) {
                          if (i >= _filtered.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))),
                            );
                          }
                          final u = _filtered[i];
                          final id = u['id'] as String? ?? '';
                          final name = ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim();
                          _names[id] = name;
                          final picked = _selected.contains(id);
                          return InkWell(
                            onTap: () => setState(() {
                              if (picked) { _selected.remove(id); }
                              else { _selected.add(id); }
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(child: Text(name,
                                      style: TextStyle(fontSize: 15, color: cs.onSurface))),
                                  if (picked)
                                    const Icon(Icons.check_circle,
                                        color: AppColors.primary, size: 22),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }
}

/// Light blue/white pill chip showing the selected member (or "Select").
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key, required this.name, required this.onTap,
    this.placeholder = 'Select',
  });
  final String       name;
  final VoidCallback onTap;
  final String       placeholder;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(name.isEmpty ? placeholder : name,
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    ),
  );
}
