import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../repositories/clock_repository.dart';

/// Scans a QR code displayed on a Time Clock Terminal kiosk.
/// Deep-link format: `<base>/mobile-checkin?org=<orgId>&token=<terminalToken>`
/// On success pops with the clock-in status string.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _processing = false;
  String? _error;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final uri = Uri.tryParse(raw);
    if (uri == null) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Invalid QR code — no terminal token found.');
      return;
    }

    setState(() { _processing = true; _error = null; });
    await _controller.stop();

    try {
      final result = await context.read<ClockRepository>().clockViaQr(
        terminalToken: token,
        action: 'in',
      );
      if (!mounted) return;
      final status = result['status'] as String? ?? 'Clocked In';
      Navigator.pop(context, status);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Terminal QR Code',
            style: TextStyle(fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay with scan reticle
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2196F3), width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Corner accents
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(painter: _CornerPainter()),
            ),
          ),

          // Instruction text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  )
                else if (_processing)
                  const CircularProgressIndicator(color: Color(0xFF2196F3))
                else
                  const Text(
                    'Point your camera at the\nTime Clock Terminal QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r   = 16.0;

    // top-left
    canvas.drawLine(Offset(r, 0), Offset(r + len, 0), paint);
    canvas.drawLine(Offset(0, r), Offset(0, r + len), paint);
    // top-right
    canvas.drawLine(Offset(size.width - r - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    // bottom-left
    canvas.drawLine(Offset(0, size.height - r - len), Offset(0, size.height - r), paint);
    canvas.drawLine(Offset(r, size.height), Offset(r + len, size.height), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width, size.height - r - len), Offset(size.width, size.height - r), paint);
    canvas.drawLine(Offset(size.width - r - len, size.height), Offset(size.width - r, size.height), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
