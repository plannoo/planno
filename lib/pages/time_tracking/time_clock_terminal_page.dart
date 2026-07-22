import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/require_admin.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import 'clock_pin_page.dart';

class TimeClockTerminalSetupPage extends StatefulWidget {
  const TimeClockTerminalSetupPage({super.key});

  @override
  State<TimeClockTerminalSetupPage> createState() => _TimeClockTerminalSetupPageState();
}

class _TimeClockTerminalSetupPageState extends State<TimeClockTerminalSetupPage> {
  List<Map<String, dynamic>> _locations = [];
  final Set<String> _selected = {};
  bool _loading  = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    if (!requireAdmin(context)) return;
    _load();
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final res = await ApiClient.instance.post('/api/terminal/session', data: {
        'label':       'Mobile Terminal',
        'locationIds': _selected.toList(),
      });
      final wrap = (res is Map<String, dynamic>) ? res : <String, dynamic>{};
      final body = (wrap['data'] ?? wrap) as Map<String, dynamic>;
      final token = body['token'] as String? ?? '';
      if (token.isEmpty) {
        throw Exception('Server did not return a terminal token');
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => TimeClockTerminalActivePage(
          locationIds:   _selected.toList(),
          terminalToken: token,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/api/locations');
      final raw  = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      if (mounted) {
        setState(() {
          _locations = List<Map<String, dynamic>>.from(raw);
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) { setState(() { _locations = []; _loading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canStart = _selected.isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canStart && !_starting ? _start : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart ? AppColors.primary : Colors.grey,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _starting
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Start time clock station',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text('Time Clock Terminal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Text(
              'Please select the locations that should be clocked in this station',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _locations.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                    itemBuilder: (_, i) {
                      final loc = _locations[i];
                      final id   = loc['id']   as String? ?? '';
                      final name = loc['name'] as String? ?? '';
                      final on   = _selected.contains(id);
                      return SwitchListTile(
                        title: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 15, color: cs.onSurface)),
                        value: on,
                        onChanged: (v) => setState(() {
                          if (v) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                        activeThumbColor: AppColors.primary,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Active terminal view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class TimeClockTerminalActivePage extends StatefulWidget {
  const TimeClockTerminalActivePage({
    super.key,
    required this.locationIds,
    required this.terminalToken,
  });
  final List<String> locationIds;
  final String       terminalToken;

  @override
  State<TimeClockTerminalActivePage> createState() => _TimeClockTerminalActivePageState();
}

class _TimeClockTerminalActivePageState extends State<TimeClockTerminalActivePage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      // Use the terminal-scoped employee list (requires terminalToken header),
      // not the global /api/users â€” terminal sessions don't have a JWT user.
      final data = await ApiClient.instance.get(
        '/api/terminal/employees',
        options: Options(headers: { 'x-terminal-token': widget.terminalToken }),
      );
      final raw  = data is List ? data
          : (data as Map<String, dynamic>)['data'] as List? ?? [];
      final users = List<Map<String, dynamic>>.from(raw)
        ..sort((a, b) {
          // online users first
          final ao = a['isClocked'] == true ? 0 : 1;
          final bo = b['isClocked'] == true ? 0 : 1;
          if (ao != bo) return ao - bo;
          return ('${a['firstName']} ${a['lastName']}')
              .compareTo('${b['firstName']} ${b['lastName']}');
        });
      if (mounted) setState(() { _users = users; _error = null; _loading = false; });
    } catch (e) {
      // A wall-mounted kiosk showing a blank list is unactionable — nobody can
      // clock in and nobody can tell whether it is broken or simply empty.
      if (mounted) {
        setState(() {
          _users = [];
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _showExitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExitTerminalSheet(terminalToken: widget.terminalToken),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Time Clock Terminal',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showExitSheet,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white60),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : (_error != null || _users.isEmpty)
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          _error ?? 'No employees to show.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (_, i) {
                        final u = _users[i];
                        final name = ('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}').trim();
                        final avatar = u['avatarUrl'] as String?;
                        final online = u['isClocked'] == true;
                        return InkWell(
                          onTap: () {
                            final id = u['id'] as String? ?? '';
                            if (id.isEmpty) return;
                            // Toggle clock action based on current status â€” if
                            // they're already clocked in, the next tap clocks out.
                            final action = u['isClocked'] == true ? 'out' : 'in';
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ClockPinPage(
                                userId:        id,
                                userName:      name,
                                terminalToken: widget.terminalToken,
                                action:        action,
                              ),
                            )).then((_) => _load());
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (avatar != null && avatar.isNotEmpty)
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: NetworkImage(avatar),
                                      )
                                    else
                                      const Icon(Icons.account_circle,
                                          color: Colors.white, size: 36),
                                    if (online)
                                      Positioned(
                                        right: -2, top: -2,
                                        child: Container(
                                          width: 12, height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.primary, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Exit terminal bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ExitTerminalSheet extends StatefulWidget {
  const _ExitTerminalSheet({required this.terminalToken});
  final String terminalToken;

  @override
  State<_ExitTerminalSheet> createState() => _ExitTerminalSheetState();
}

class _ExitTerminalSheetState extends State<_ExitTerminalSheet> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  bool get _canSubmit =>
      _emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty;

  Future<void> _exit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      // The right endpoint is `DELETE /api/terminal/session` â€” it verifies the
      // manager's credentials AND tears down the terminal session so the kiosk
      // token can no longer be used. Using `/auth/login` would create a logged-in
      // user session instead, which is the wrong outcome.
      await ApiClient.instance.delete('/api/terminal/session', data: {
        'token':    widget.terminalToken,
        'email':    _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.of(context).pop(); // pop terminal active page
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 22, color: cs.onSurfaceVariant),
                ),
                const Expanded(
                  child: Text('Exit time clock terminal',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 22),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manager email',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'E-Mail',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Password',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !_submitting ? _exit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit ? AppColors.primary : Colors.grey,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      disabledForegroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Exit time clock terminal',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
