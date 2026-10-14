import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'analysis_loading_screen.dart';

class ConfirmImageScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const ConfirmImageScreen({super.key, required this.imageBytes});

  static const Color backgroundColor = Color(0xFFF7FBF8);
  static const Color primaryGreen = Color(0xFF238252);
  static const Color darkText = Color(0xFF123D2F);
  static const Color secondaryText = Color(0xFF73817B);
  static const Color lightGreen = Color(0xFFEFFFF4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(21, 17, 21, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePreview(),

                    const SizedBox(height: 25),

                    _buildReadyLabel(),

                    const SizedBox(height: 8),

                    const Text(
                      'Sẵn sàng phân tích?',
                      style: TextStyle(
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Hãy đảm bảo lá lúa hiển thị rõ trước khi phân tích.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: secondaryText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 21),

                    _buildAnalyzeButton(context),

                    const SizedBox(height: 15),

                    _buildRetakeButton(context),
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

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back,
                  size: 23,
                  color: Color(0xFF476A5C),
                ),
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              'Xác nhận ảnh',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),

            const Spacer(),

            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => _showMoreMenu(context),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.more_horiz,
                  size: 23,
                  color: Color(0xFF476A5C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // IMAGE
  // ===============================================================

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 337,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF1F6F3),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 42,
                    color: Color(0xFF9AACA3),
                  ),
                );
              },
            ),

            Positioned(left: 15, bottom: 13, child: _buildImageStatus()),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: primaryGreen),
          SizedBox(width: 6),
          Text(
            'Ảnh đủ rõ nét',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // READY LABEL
  // ===============================================================

  Widget _buildReadyLabel() {
    return const Text(
      'ẢNH ĐÃ SẴN SÀNG',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF599376),
      ),
    );
  }

  // ===============================================================
  // ANALYZE BUTTON
  // ===============================================================

  Widget _buildAnalyzeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AnalysisLoadingScreen(imageBytes: imageBytes),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Phân tích bệnh',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 9),
            Icon(Icons.chevron_right, size: 21),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // RETAKE
  // ===============================================================

  Widget _buildRetakeButton(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF507A69),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 17),
            SizedBox(width: 7),
            Text(
              'Chụp lại ảnh',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // MORE MENU
  // ===============================================================

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.image_outlined,
                    color: primaryGreen,
                  ),
                  title: const Text('Ảnh hiện tại'),
                  subtitle: const Text('Ảnh đã chọn để phân tích'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
