import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';

class ClockPinPage extends StatefulWidget {
  const ClockPinPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.terminalToken,
    this.action = 'in',
  });
  final String userId;
  final String userName;
  /// Token from `TerminalSession` — required for `/api/terminal/clock`.
  final String terminalToken;
  /// 'in' | 'out' | 'break_start' | 'break_end'
  final String action;

  @override
  State<ClockPinPage> createState() => _ClockPinPageState();
}

class _ClockPinPageState extends State<ClockPinPage> {
  String _pin = '';
  bool   _submitting = false;
  int    _failedAttempts = 0;
  DateTime? _lockedUntil;
  static const _maxLen = 4;
  static const _maxAttempts = 5;
  static const _lockoutDuration = Duration(seconds: 30);

  bool get _isLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  int get _lockSecondsLeft =>
      _lockedUntil == null ? 0
        : _lockedUntil!.difference(DateTime.now()).inSeconds.clamp(0, 999);

  void _tap(String digit) {
    if (_isLocked || _pin.length >= _maxLen) return;
    setState(() => _pin += digit);
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_pin.length < _maxLen || _submitting || _isLocked) return;
    setState(() => _submitting = true);
    try {
      await ApiClient.instance.post(
        '/api/terminal/clock',
        data: {
          'employeeId': widget.userId,
          'pin':        _pin,
          'action':     widget.action,
        },
        // The terminal session token is sent via header — terminalAuth middleware
        // reads `x-terminal-token` to identify the kiosk.
        options: Options(headers: { 'x-terminal-token': widget.terminalToken }),
      );
      if (!mounted) return;
      _failedAttempts = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clocked!'),
            backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      // The kiosk can now be refused for reasons that have nothing to do with the
      // PIN — no shift scheduled, already clocked in, QR disabled by the org.
      // Counting those as wrong-PIN attempts locked people out of the terminal
      // while showing them an explanation that was simply untrue.
      final isPinFailure = message.toLowerCase().contains('pin');
      if (!isPinFailure) {
        setState(() { _submitting = false; _pin = ''; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message),
              backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
        return;
      }

      _failedAttempts++;
      // Client-side lockout — defense in depth. Backend MUST also rate-limit.
      if (_failedAttempts >= _maxAttempts) {
        _lockedUntil = DateTime.now().add(_lockoutDuration);
        _scheduleUnlock();
      }
      setState(() { _submitting = false; _pin = ''; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLocked
              ? 'Too many failed attempts. Try again in ${_lockSecondsLeft}s.'
              : 'Incorrect PIN. ${_maxAttempts - _failedAttempts} attempts left.'),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _scheduleUnlock() {
    Future.delayed(_lockoutDuration, () {
      if (!mounted) return;
      setState(() {
        _lockedUntil    = null;
        _failedAttempts = 0;
      });
    });
    // Tick once a second so the countdown updates.
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (!_isLocked) return false;
      setState(() {}); // rebuild to refresh _lockSecondsLeft
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 14),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white60),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ),
                  Expanded(
                    child: Text(widget.userName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // PIN display
            Container(
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                List.filled(_pin.length, '•').join('   '),
                style: const TextStyle(
                    color: Colors.white, fontSize: 26, letterSpacing: 6),
              ),
            ),
            if (_isLocked) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Locked. Try again in ${_lockSecondsLeft}s',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
            const SizedBox(height: 40),

            // Keypad
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _row(['1', '2', '3']),
                    const SizedBox(height: 20),
                    _row(['4', '5', '6']),
                    const SizedBox(height: 20),
                    _row(['7', '8', '9']),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _key(
                          color: AppColors.error,
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                          onTap: _backspace,
                        ),
                        _digit('0'),
                        _key(
                          color: Colors.transparent,
                          border: true,
                          child: _submitting
                              ? const SizedBox(width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : const Icon(Icons.check,
                                  color: Colors.white, size: 28),
                          onTap: _submit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: digits.map(_digit).toList(),
  );

  Widget _digit(String d) => _key(
    color: Colors.white.withValues(alpha: 0.18),
    child: Text(d,
        style: const TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w500)),
    onTap: () => _tap(d),
  );

  Widget _key({
    required Color color, required Widget child, required VoidCallback onTap,
    bool border = false,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 78, height: 78,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border ? Border.all(color: Colors.white60, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: child,
    ),
  );
}
