import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/require_admin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/user_search.dart';
import '../../../core/theme/app_colors.dart';
import 'employee_detail_page.dart';

class EmployeesPage extends StatefulWidget {
  const EmployeesPage({super.key});

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  final _pager = UserSearchPager();
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> get _filtered => _pager.users;

  @override
  void initState() {
    super.initState();
    if (!requireAdmin(context)) return;
    _load(reset: true);
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        _load(reset: true, query: _searchCtrl.text.trim());
      });
    });
  }

  @override
  void dispose() { _debounce?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        _pager.hasMore && !_pager.isLoading) {
      _load();
    }
    return false;
  }

  void _showInvite() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteSheet(),
    );
  }

  Future<void> _load({bool reset = false, String? query}) async {
    if (reset) setState(() => _loading = true);
    await _pager.load(reset: reset, query: query);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
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
                    const Text('Employees',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showInvite,
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 18),
                      label: const Text('Invite',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Employee search',
                hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
                prefixIcon: Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
                filled: true,
                fillColor: cs.surface,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Text('No employees found',
                        style: TextStyle(color: cs.onSurfaceVariant)))
                    : NotificationListener<ScrollNotification>(
                        onNotification: _onScroll,
                        child: ListView.separated(
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
                            final name = ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim();
                            final avatar = u['avatarUrl'] as String?;
                            return InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => EmployeeDetailPage(
                                    userId: u['id'] as String? ?? '', name: name),
                              )),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    if (avatar != null && avatar.isNotEmpty)
                                      CircleAvatar(
                                          radius: 20, backgroundImage: NetworkImage(avatar))
                                    else
                                      Container(
                                        width: 40, height: 40,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary, shape: BoxShape.circle),
                                        child: const Icon(Icons.person,
                                            color: Colors.white, size: 24),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(name,
                                          style: TextStyle(fontSize: 15, color: cs.onSurface)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Invite employee sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _InviteSheet extends StatefulWidget {
  const _InviteSheet();

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _email = TextEditingController();
  String _role = 'EMPLOYEE';
  bool _sending = false;

  @override
  void dispose() { _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid email'),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post('/api/auth/invite',
          data: {'email': email, 'role': _role});
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Invitation sent to $email'),
        behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invite employee',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 16),
                Text('Email', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 6),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'name@company.com',
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Role', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['EMPLOYEE', 'MANAGER', 'ADMIN'].map((r) {
                    final sel = _role == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: sel,
                      onSelected: (_) => setState(() => _role = r),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : cs.onSurface,
                          fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _sending
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Send invitation',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
