import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'confirm_image_screen.dart';
import 'page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _cameraInitialized = false;
  bool _cameraLoading = true;
  bool _isRearCamera = true;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _initializeCamera();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ===============================================================
  // CAMERA INITIALIZATION
  // ===============================================================

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    setState(() {
      _cameraLoading = true;
    });

    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _cameraLoading = false;
          _cameraInitialized = false;
        });

        return;
      }

      CameraDescription selectedCamera = _cameras.first;

      for (final camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _isRearCamera = selectedCamera.lensDirection == CameraLensDirection.back;

      await _startCamera(selectedCamera);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraLoading = false;
        _cameraInitialized = false;
      });

      _showMessage('Không thể mở camera: $e');
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    await _cameraController?.dispose();

    if (!mounted) return;

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController = controller;

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraInitialized = true;
        _cameraLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cameraInitialized = false;
        _cameraLoading = false;
      });

      _showMessage('Không thể khởi tạo camera: $e');
    }
  }

  // ===============================================================
  // TAKE PICTURE
  // ===============================================================

  Future<void> _takePicture() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile picture = await controller.takePicture();

      final Uint8List imageBytes = await picture.readAsBytes();

      if (!mounted) return;

      await Navigator.push(
        context,
        smoothRoute(ConfirmImageScreen(imageBytes: imageBytes)),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Không thể chụp ảnh: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  // ===============================================================
  // PICK IMAGE FROM GALLERY
  // ===============================================================

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;

      Uint8List? imageBytes = file.bytes;

      if (imageBytes == null && file.path != null) {
        imageBytes = await XFile(file.path!).readAsBytes();
      }

      if (imageBytes == null) {
        throw Exception('Không đọc được dữ liệu ảnh.');
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        smoothRoute(ConfirmImageScreen(imageBytes: imageBytes)),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Không thể mở ảnh: $e');
    }
  }

  // ===============================================================
  // SWITCH CAMERA
  // ===============================================================

  Future<void> _switchCamera() async {
    if (_isTakingPicture || _cameraLoading) {
      return;
    }

    if (_cameras.length < 2) {
      _showMessage(
        'Thiết bị không có camera trước/sau khác.',
        duration: const Duration(milliseconds: 900),
      );

      return;
    }

    final targetDirection = _isRearCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    CameraDescription? nextCamera;

    for (final camera in _cameras) {
      if (camera.lensDirection == targetDirection) {
        nextCamera = camera;
        break;
      }
    }

    if (nextCamera == null) {
      return;
    }

    setState(() {
      _cameraLoading = true;
      _cameraInitialized = false;
    });

    _isRearCamera = targetDirection == CameraLensDirection.back;

    await _startCamera(nextCamera);
  }

  // ===============================================================
  // MESSAGE
  // ===============================================================

  void _showMessage(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Column(
            children: [
              _buildHeader(),

              const SizedBox(height: 31),

              _buildTitle(),

              const SizedBox(height: 20),

              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildScanner()),

                    const SizedBox(height: 25),

                    _buildCameraControls(),

                    const SizedBox(height: 17),

                    Text(
                      _isRearCamera
                          ? 'Camera sau • Hướng camera vào một lá lúa'
                          : 'Camera trước • Hướng camera vào một lá lúa',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF7FA08D),
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // TITLE
  // ===============================================================

  Widget _buildTitle() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: Color(0xFF75A789)),
              SizedBox(width: 5),
              Text(
                'AI SẴN SÀNG QUÉT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xFF6B967C),
                ),
              ),
            ],
          ),

          SizedBox(height: 13),

          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Hãy kiểm tra\n',
                  style: TextStyle(color: Color(0xFF073D2C)),
                ),
                TextSpan(
                  text: 'lá lúa của bạn.',
                  style: TextStyle(color: Color(0xFF2B8758)),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 29,
              height: 0.98,
              fontWeight: FontWeight.w400,
              letterSpacing: -1.0,
            ),
          ),

          SizedBox(height: 9),

          Text(
            'Phát hiện sớm dấu hiệu bệnh trước khi chúng lan rộng.',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF789087),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader() {
    return SizedBox(
      height: 53,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF217A4D),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF217A4D).withOpacity(0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Colors.white,
              size: 23,
            ),
          ),

          const SizedBox(width: 10),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI4Life',
                style: TextStyle(
                  color: Color(0xFF06412D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Chăm sóc lúa thông minh',
                style: TextStyle(
                  color: Color(0xFF789087),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),

          const Spacer(),

          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.tune, size: 21, color: Color(0xFF47745D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SCANNER
  // ===============================================================

  Widget _buildScanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),

          Container(color: Colors.black.withOpacity(0.08)),

          const Positioned.fill(child: _ScanCorners()),

          AnimatedBuilder(
            animation: _scanController,
            builder: (context, child) {
              return Positioned(
                left: 37,
                right: 37,
                top:
                    45 +
                    (_scanController.value *
                        (MediaQuery.of(context).size.height * 0.38)),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFB9F4B8).withOpacity(0.95),
                        const Color(0xFFB9F4B8).withOpacity(0.95),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9DF09D).withOpacity(0.45),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: 15,
            left: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isRearCamera
                        ? Icons.camera_rear_outlined
                        : Icons.camera_front_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isRearCamera ? 'Camera sau' : 'Camera trước',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.crop_free, color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text(
                      'Đặt lá vào trong khung',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Ánh sáng tốt giúp kết quả chính xác hơn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CAMERA PREVIEW
  // ===============================================================

  Widget _buildCameraPreview() {
    if (_cameraLoading) {
      return Container(
        color: const Color(0xFF536B46),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (!_cameraInitialized || _cameraController == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9CAA45), Color(0xFF65862D), Color(0xFF315E25)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt_outlined,
            color: Colors.white54,
            size: 70,
          ),
        ),
      );
    }

    final previewSize = _cameraController!.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(_cameraController!);
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // ===============================================================
  // CAMERA CONTROLS
  // ===============================================================

  Widget _buildCameraControls() {
    return SizedBox(
      height: 67,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSideButton(
            icon: Icons.image_outlined,
            label: 'Thư viện',
            onTap: _pickImage,
          ),

          GestureDetector(
            onTap: _takePicture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTakingPicture
                    ? const Color(0xFF1E7048)
                    : const Color(0xFF2A8957),
                border: Border.all(color: const Color(0xFFE2F1E7), width: 6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A8957).withOpacity(0.22),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: _isTakingPicture
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),

          _buildSideButton(
            icon: _isRearCamera
                ? Icons.camera_front_outlined
                : Icons.camera_rear_outlined,
            label: 'Đổi camera',
            onTap: _switchCamera,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SIDE BUTTON
  // ===============================================================

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: const Color(0xFF5F846F)),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF698A77),
                fontSize: 9.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SCAN CORNERS
// ================================================================

class _ScanCorners extends StatelessWidget {
  const _ScanCorners();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 30,
          top: 58,
          child: _Corner(top: true, left: true),
        ),
        const Positioned(
          right: 30,
          top: 58,
          child: _Corner(top: true, left: false),
        ),
        const Positioned(
          left: 30,
          bottom: 67,
          child: _Corner(top: false, left: true),
        ),
        const Positioned(
          right: 30,
          bottom: 67,
          child: _Corner(top: false, left: false),
        ),
      ],
    );
  }
}

// ================================================================
// CORNER
// ================================================================

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;

  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _CornerPainter(color: Colors.white, top: top, left: left),
      ),
    );
  }
}

// ================================================================
// CORNER PAINTER
// ================================================================

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool top;
  final bool left;

  _CornerPainter({required this.color, required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (top && left) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(8, 0)
        ..quadraticBezierTo(0, 0, 0, 8)
        ..lineTo(0, size.height);
    } else if (top && !left) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width - 8, 0)
        ..quadraticBezierTo(size.width, 0, size.width, 8)
        ..lineTo(size.width, size.height);
    } else if (!top && left) {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height - 8)
        ..quadraticBezierTo(0, size.height, 8, size.height)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height - 8)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width - 8,
          size.height,
        )
        ..lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return false;
  }
}
