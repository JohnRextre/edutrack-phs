import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/qr_service.dart';

class QrCameraScannerScreen extends StatefulWidget {
  const QrCameraScannerScreen({super.key});

  @override
  State<QrCameraScannerScreen> createState() => _QrCameraScannerScreenState();
}

class _QrCameraScannerScreenState extends State<QrCameraScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualPayloadController =
      TextEditingController();
  bool _hasReturnedResult = false;
  bool _isTorchEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualPayloadController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || _hasReturnedResult) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
    }
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasReturnedResult) return;

    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;
    if (!QrService.isEduTrackPayload(rawValue)) {
      _showGalleryMessage(
        'This is not an EduTrack PHS QR code. Please scan an EduTrack resource QR code.',
      );
      return;
    }

    _hasReturnedResult = true;
    _controller.stop();
    Navigator.of(context).pop(rawValue);
  }

  Future<void> _openManualEntry() async {
    _manualPayloadController.clear();
    final payload = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Item Code or QR Payload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the Item Code (e.g. LAP-001) or paste the full QR payload below.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualPayloadController,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Item Code / Payload',
                hintText: 'e.g. LAP-001 or System: EduTrack PHS...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = _manualPayloadController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted || payload == null || payload.trim().isEmpty) return;
    _hasReturnedResult = true;
    _controller.stop();
    Navigator.of(context).pop(payload);
  }

  Future<void> _pickQrImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted || picked == null) return;

    final capture = await _controller.analyzeImage(picked.path);
    if (!mounted) return;
    final rawValue = capture?.barcodes.firstOrNull?.rawValue?.trim();
    if (rawValue == null || rawValue.isEmpty) {
      _showGalleryMessage(
        'No QR code was found in that image. Please choose a clear EduTrack QR code.',
      );
      return;
    }
    if (!QrService.isEduTrackPayload(rawValue)) {
      _showGalleryMessage(
        'This is not an EduTrack PHS QR code. Please choose an EduTrack resource QR image.',
      );
      return;
    }

    _hasReturnedResult = true;
    _controller.stop();
    Navigator.of(context).pop(rawValue);
  }

  void _showGalleryMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) {
      setState(() => _isTorchEnabled = !_isTorchEnabled);
    }
  }

  Future<void> _switchCamera() => _controller.switchCamera();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetection),
          const _ScannerOverlay(),
          // Top Navigation & Action Bar - explicitly pinned to the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ScannerIconButton(
                      tooltip: 'Close scanner',
                      icon: Icons.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Scan QR to Borrow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black87,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScannerIconButton(
                          tooltip: 'Choose QR image',
                          icon: Icons.image_search_outlined,
                          onPressed: _pickQrImage,
                        ),
                        const SizedBox(width: 8),
                        _ScannerIconButton(
                          tooltip: 'Toggle flash',
                          icon: _isTorchEnabled
                              ? Icons.flash_on
                              : Icons.flash_off,
                          onPressed: _toggleTorch,
                        ),
                        const SizedBox(width: 8),
                        _ScannerIconButton(
                          tooltip: 'Flip camera',
                          icon: Icons.flip_camera_ios,
                          onPressed: _switchCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Helper label positioned right below the scanner frame (frame is 270x270 in center)
          Positioned(
            left: 24,
            right: 24,
            top: (screenHeight / 2) + 148,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: const Text(
                  'Point camera at the item\'s QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Bottom button for manual entry
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: SafeArea(
              top: false,
              child: Center(
                child: TextButton.icon(
                  onPressed: _openManualEntry,
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                  label: const Text('Enter code manually'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.65),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerIconButton extends StatelessWidget {
  const _ScannerIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon, color: Colors.white),
    style: IconButton.styleFrom(backgroundColor: Colors.black54),
  );
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScannerOverlayPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanSize = 270.0;
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanSize,
      height: scanSize,
    );
    final shadePaint = Paint()..color = Colors.black.withValues(alpha: .58);
    final clearPath = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(18)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(clearPath, shadePaint);

    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const cornerLength = 30.0;
    final corners = [
      [scanRect.topLeft, scanRect.topLeft + const Offset(cornerLength, 0)],
      [scanRect.topLeft, scanRect.topLeft + const Offset(0, cornerLength)],
      [scanRect.topRight, scanRect.topRight + const Offset(-cornerLength, 0)],
      [scanRect.topRight, scanRect.topRight + const Offset(0, cornerLength)],
      [
        scanRect.bottomLeft,
        scanRect.bottomLeft + const Offset(cornerLength, 0),
      ],
      [
        scanRect.bottomLeft,
        scanRect.bottomLeft + const Offset(0, -cornerLength),
      ],
      [
        scanRect.bottomRight,
        scanRect.bottomRight + const Offset(-cornerLength, 0),
      ],
      [
        scanRect.bottomRight,
        scanRect.bottomRight + const Offset(0, -cornerLength),
      ],
    ];
    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
