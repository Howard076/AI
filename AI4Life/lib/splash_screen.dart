import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onFinished});

  /// Gọi callback này khi splash kết thúc.
  /// Ví dụ:
  /// onFinished: () {
  ///   Navigator.pushReplacement(...);
  /// }
  final VoidCallback? onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _circleController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;

  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    // =========================================================
    // MAIN ANIMATION
    // =========================================================

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo:
    // 0 -> 350ms
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // Title:
    // xuất hiện sau logo
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.25, 0.50, curve: Curves.easeOut),
      ),
    );

    // Subtitle
    _subtitleSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.42, 0.70, curve: Curves.easeOutCubic),
          ),
        );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
      ),
    );

    // =========================================================
    // DECORATIVE CIRCLES
    // =========================================================

    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // =========================================================
    // LOADING BAR
    // =========================================================

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Bắt đầu animation chính
    _mainController.forward();

    // Sau 3 giây chuyển màn hình
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;

      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _circleController.dispose();
    _loadingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===================================================
          // BACKGROUND
          // ===================================================
          const _Background(),

          // ===================================================
          // DECORATIVE CIRCLES
          // ===================================================
          AnimatedBuilder(
            animation: _circleController,
            builder: (context, child) {
              final value = _circleController.value;

              return Stack(
                children: [
                  // Circle trên bên phải
                  Positioned(
                    right: -110 + math.sin(value * math.pi * 2) * 12,
                    top: -120 + math.cos(value * math.pi * 2) * 8,
                    child: const _DecorativeCircle(size: 240),
                  ),

                  // Circle dưới bên trái
                  Positioned(
                    left: -120 + math.cos(value * math.pi * 2) * 10,
                    bottom: -125 + math.sin(value * math.pi * 2) * 8,
                    child: const _DecorativeCircle(size: 240),
                  ),
                ],
              );
            },
          ),

          // ===================================================
          // MAIN CONTENT
          // ===================================================
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -------------------------------
                    // LOGO
                    // -------------------------------
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: const _Logo(),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // -------------------------------
                    // APP NAME
                    // -------------------------------
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'AI4Life',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // -------------------------------
                    // SUBTITLE
                    // -------------------------------
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: const Text(
                          'Chăm sóc lúa thông minh',
                          style: TextStyle(
                            color: Color(0xFFDCEFE3),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 42),

                    // -------------------------------
                    // LOADING LINE
                    // -------------------------------
                    AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 42,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CustomPaint(
                              painter: _LoadingPainter(
                                progress: _loadingController.value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// BACKGROUND
// =============================================================

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF176A45), Color(0xFF227B50), Color(0xFF2E895B)],
        ),
      ),
    );
  }
}

// =============================================================
// LOGO
// =============================================================

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFF2FFF5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.eco_outlined, size: 48, color: Color(0xFF218452)),
      ),
    );
  }
}

// =============================================================
// DECORATIVE CIRCLE
// =============================================================

class _DecorativeCircle extends StatelessWidget {
  final double size;

  const _DecorativeCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
      ),
    );
  }
}

// =============================================================
// LOADING PAINTER
// =============================================================

class _LoadingPainter extends CustomPainter {
  final double progress;

  _LoadingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final foregroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Background
    final backgroundRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(20),
    );

    canvas.drawRRect(backgroundRect, backgroundPaint);

    // Loading animation
    const loadingWidth = 18.0;

    final x = (size.width + loadingWidth) * progress - loadingWidth;

    final loadingRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, 0, loadingWidth, size.height),
      const Radius.circular(20),
    );

    canvas.drawRRect(loadingRect, foregroundPaint);
  }

  @override
  bool shouldRepaint(covariant _LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
