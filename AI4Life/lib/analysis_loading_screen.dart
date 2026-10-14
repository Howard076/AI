import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'scan_result_screen.dart';

class AnalysisLoadingScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const AnalysisLoadingScreen({super.key, required this.imageBytes});

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _scanController;

  Timer? _analysisTimer;

  int _currentStep = 0;

  bool _isAnalyzing = true;
  bool _hasError = false;
  String _errorMessage = '';

  final List<String> _steps = [
    'Đang chuẩn bị ảnh...',
    'Đang nhận diện lá lúa...',
    'Đang phân tích dấu hiệu bệnh...',
    'Đang hoàn tất kết quả...',
  ];

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _startAnalysis();
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();

    _rotationController.dispose();
    _pulseController.dispose();
    _scanController.dispose();

    super.dispose();
  }

  // ===============================================================
  // ANALYSIS
  // ===============================================================

  Future<void> _startAnalysis() async {
    _startStepAnimation();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://127.0.0.1:8000/predict'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          widget.imageBytes,
          filename: 'rice_leaf.jpg',
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (!mounted) return;

      if (streamedResponse.statusCode != 200) {
        throw Exception(
          'Server trả về lỗi ${streamedResponse.statusCode}: $responseBody',
        );
      }

      final data = jsonDecode(responseBody);

      if (data['success'] != true) {
        throw Exception('AI không thể phân tích ảnh.');
      }

      _analysisTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _currentStep = _steps.length - 1;
        _isAnalyzing = false;
      });

      // Cho người dùng nhìn thấy bước hoàn tất một chút.
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _showResult(data);
    } catch (e) {
      _analysisTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        _hasError = true;
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  void _startStepAnimation() {
    _analysisTimer?.cancel();

    // Animation UI vẫn chạy trong lúc model đang xử lý thật.
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentStep < _steps.length - 2) {
        setState(() {
          _currentStep++;
        });
      }
    });
  }

  String _getErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('Connection refused') ||
        message.contains('Failed host lookup')) {
      return 'Không thể kết nối tới AI Server.\n'
          'Hãy kiểm tra FastAPI đang chạy ở port 8000.';
    }

    if (message.contains('TimeoutException')) {
      return 'AI Server xử lý quá lâu.\n'
          'Vui lòng thử lại.';
    }

    return 'Không thể phân tích ảnh.\n'
        'Chi tiết: $message';
  }

  void _showResult(Map<String, dynamic> data) {
    if (!mounted) return;

    _analysisTimer?.cancel();

    final prediction = data['prediction'] as String? ?? 'Unknown';

    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

    final topPredictions = (data['top_predictions'] as List<dynamic>?) ?? [];

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ScanResultScreen(
            imageBytes: widget.imageBytes,
            prediction: prediction,
            confidence: confidence,
            topPredictions: topPredictions,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    const Spacer(),

                    _buildImageScanner(),

                    const SizedBox(height: 35),

                    Text(
                      _hasError ? 'Không thể phân tích' : 'AI đang phân tích',
                      style: const TextStyle(
                        color: Color(0xFF123D2F),
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _hasError ? _errorMessage : _steps[_currentStep],
                        key: ValueKey(_hasError ? _errorMessage : _currentStep),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF73817B),
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 27),

                    _buildProgress(),

                    const SizedBox(height: 20),

                    _buildStepList(),

                    const Spacer(),

                    if (_hasError) _buildRetryButton(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // HEADER
  // ===============================================================

  Widget _buildHeader() {
    return SizedBox(
      height: 65,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF238252), size: 20),
            const SizedBox(width: 10),
            const Text(
              'AI4Life',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF123D2F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // IMAGE SCANNER
  // ===============================================================

  Widget _buildImageScanner() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 0.98 + (_pulseController.value * 0.02);

        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 235,
        height: 235,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF238252).withOpacity(0.13),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(widget.imageBytes, fit: BoxFit.cover),

              Container(color: Colors.black.withOpacity(0.20)),

              if (!_hasError)
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, child) {
                    return Positioned(
                      left: 12,
                      right: 12,
                      top: 20 + (_scanController.value * 190),
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFB9F4B8),
                              Color(0xFFB9F4B8),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8EF08F).withOpacity(0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              Center(
                child: _hasError
                    ? Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      )
                    : const _ScanningIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // PROGRESS
  // ===============================================================

  Widget _buildProgress() {
    final progress = (_currentStep + 1) / _steps.length;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: const Color(0xFFDDEBE2),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF238252)),
          ),
        ),

        const SizedBox(height: 9),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đang xử lý',
              style: TextStyle(fontSize: 10, color: Color(0xFF799087)),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF238252),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===============================================================
  // STEPS
  // ===============================================================

  Widget _buildStepList() {
    return Column(
      children: List.generate(_steps.length, (index) {
        final completed = index < _currentStep;
        final active = index == _currentStep;

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed || active
                      ? const Color(0xFFE5F4EA)
                      : const Color(0xFFF0F5F2),
                ),
                child: completed
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Color(0xFF238252),
                      )
                    : active && !_hasError
                    ? const Padding(
                        padding: EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF238252),
                          ),
                        ),
                      )
                    : _hasError && active
                    ? const Icon(Icons.close, size: 14, color: Colors.redAccent)
                    : null,
              ),

              const SizedBox(width: 11),

              Text(
                _steps[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active || completed
                      ? const Color(0xFF416B59)
                      : const Color(0xFFA0AEA8),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ===============================================================
  // RETRY
  // ===============================================================

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentStep = 0;
            _hasError = false;
            _isAnalyzing = true;
            _errorMessage = '';
          });

          _startAnalysis();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF238252),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Thử lại',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ================================================================
// SCANNING INDICATOR
// ================================================================

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.30),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
    );
  }
}
