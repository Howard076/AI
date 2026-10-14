import 'dart:typed_data';
import 'ai_chat_screen.dart';
import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  final Uint8List imageBytes;

  final String prediction;
  final double confidence;
  final List<dynamic> topPredictions;

  const ScanResultScreen({
    super.key,
    required this.imageBytes,
    required this.prediction,
    required this.confidence,
    required this.topPredictions,
  });

  static const Color backgroundColor = Color(0xFFF7FBF8);
  static const Color primaryGreen = Color(0xFF238252);
  static const Color darkText = Color(0xFF123D2F);
  static const Color secondaryText = Color(0xFF73817B);

  // ===============================================================
  // VIETNAMESE DISEASE NAME
  // ===============================================================

  String get diseaseVietnameseName {
    switch (prediction) {
      case 'Bacterial_Leaf_Blight':
        return 'Bệnh bạc lá';

      case 'Brown_Spot':
        return 'Bệnh đốm nâu';

      case 'Healthy_Rice_Leaf':
        return 'Lá lúa khỏe mạnh';

      case 'Leaf_Blast':
        return 'Bệnh đạo ôn';

      case 'Leaf_scald':
        return 'Bệnh cháy lá';

      case 'Sheath_Blight':
        return 'Bệnh khô vằn';

      default:
        return prediction.replaceAll('_', ' ');
    }
  }

  // ===============================================================
  // DESCRIPTION
  // ===============================================================

  String get diseaseDescription {
    switch (prediction) {
      case 'Bacterial_Leaf_Blight':
        return 'Bệnh bạc lá do vi khuẩn gây ra, thường tạo các vết bệnh màu vàng nhạt đến trắng dọc theo mép và đầu lá.';

      case 'Brown_Spot':
        return 'Bệnh đốm nâu thường tạo các đốm hình tròn hoặc hình bầu dục màu nâu trên lá lúa.';

      case 'Healthy_Rice_Leaf':
        return 'Mô hình không phát hiện dấu hiệu rõ ràng của các bệnh có trong dữ liệu huấn luyện.';

      case 'Leaf_Blast':
        return 'Bệnh đạo ôn thường tạo các vết bệnh hình thoi trên lá và có thể ảnh hưởng đến sự sinh trưởng của cây lúa.';

      case 'Leaf_scald':
        return 'Bệnh cháy lá tạo các vùng tổn thương màu nâu hoặc vàng trên phiến lá và có thể lan rộng khi điều kiện thuận lợi.';

      case 'Sheath_Blight':
        return 'Bệnh khô vằn thường xuất hiện các vết bệnh hình bầu dục màu xanh xám hoặc nâu trên bẹ lá, sau đó có thể lan lên các phần phía trên của cây.';

      default:
        return 'Mô hình AI đã phân tích hình ảnh lá lúa và đưa ra kết quả dự đoán này.';
    }
  }

  // ===============================================================
  // CONFIDENCE LEVEL
  // ===============================================================

  String get confidenceLevel {
    if (confidence >= 80) {
      return 'Cao';
    }

    if (confidence >= 60) {
      return 'Trung bình';
    }

    return 'Thấp';
  }

  Color get confidenceColor {
    if (confidence >= 80) {
      return const Color(0xFF238252);
    }

    if (confidence >= 60) {
      return const Color(0xFFD8892C);
    }

    return const Color(0xFFC85C5C);
  }

  // ===============================================================
  // BUILD
  // ===============================================================

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
                padding: const EdgeInsets.fromLTRB(17, 19, 17, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImage(),

                    const SizedBox(height: 22),

                    _buildDetectedLabel(),

                    const SizedBox(height: 8),

                    _buildDiseaseInfo(),

                    const SizedBox(height: 18),

                    _buildDescription(),

                    const SizedBox(height: 20),

                    _buildTopPredictions(),

                    const SizedBox(height: 20),

                    _buildChatButton(context),

                    const SizedBox(height: 10),

                    _buildScanAgainButton(context),
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
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back,
                  size: 22,
                  color: Color(0xFF476A5C),
                ),
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              'Kết quả quét',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),

            const Spacer(),

            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                _showMoreMenu(context);
              },
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

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 193,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(imageBytes, fit: BoxFit.cover),

            Positioned(
              left: 13,
              bottom: 13,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFFF4),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  'Đã phân tích xong',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF23784F),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // DETECTED LABEL
  // ===============================================================

  Widget _buildDetectedLabel() {
    final isHealthy = prediction == 'Healthy_Rice_Leaf';

    return Text(
      isHealthy ? 'KẾT QUẢ PHÂN TÍCH' : 'ĐÃ PHÁT HIỆN BỆNH',
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF599376),
      ),
    );
  }

  // ===============================================================
  // DISEASE INFO
  // ===============================================================

  Widget _buildDiseaseInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            diseaseVietnameseName,
            style: const TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.7,
              color: darkText,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${confidence.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),

                  const TextSpan(
                    text: ' độ tin cậy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: confidenceColor),

                const SizedBox(width: 5),

                Text(
                  confidenceLevel,
                  style: TextStyle(
                    fontSize: 10,
                    color: confidenceColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ===============================================================
  // DESCRIPTION
  // ===============================================================

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mức độ',
          style: TextStyle(fontSize: 9.5, color: Color(0xFF8A9B93)),
        ),

        const SizedBox(height: 18),

        Text(
          diseaseDescription,
          style: const TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Color(0xFF6F8179),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // TOP PREDICTIONS
  // ===============================================================

  Widget _buildTopPredictions() {
    if (topPredictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0ECE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các khả năng dự đoán',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),

          const SizedBox(height: 13),

          ...List.generate(topPredictions.length, (index) {
            final item = topPredictions[index];

            final className = item['class_name']?.toString() ?? '';

            final itemConfidence =
                (item['confidence'] as num?)?.toDouble() ?? 0.0;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == topPredictions.length - 1 ? 0 : 10,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${index + 1}.',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A9B93),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      _formatClassName(className),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF536D61),
                      ),
                    ),
                  ),

                  Text(
                    '${itemConfidence.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===============================================================
  // FORMAT CLASS NAME
  // ===============================================================

  String _formatClassName(String className) {
    switch (className) {
      case 'Bacterial_Leaf_Blight':
        return 'Bệnh bạc lá';

      case 'Brown_Spot':
        return 'Bệnh đốm nâu';

      case 'Healthy_Rice_Leaf':
        return 'Lá lúa khỏe mạnh';

      case 'Leaf_Blast':
        return 'Bệnh đạo ôn';

      case 'Leaf_scald':
        return 'Bệnh cháy lá';

      case 'Sheath_Blight':
        return 'Bệnh khô vằn';

      default:
        return className.replaceAll('_', ' ');
    }
  }

  // ===============================================================
  // CHAT BUTTON
  // ===============================================================

  Widget _buildChatButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AIChatScreen(
                imageBytes: imageBytes,
                prediction: prediction,
                confidence: confidence,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Trò chuyện với trợ lý AI',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),

            SizedBox(width: 7),

            Icon(Icons.chevron_right, size: 19),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // SCAN AGAIN
  // ===============================================================

  Widget _buildScanAgainButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          backgroundColor: Colors.transparent,
          side: const BorderSide(color: Color(0xFFB8DCC6), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Quét lá khác',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
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
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: primaryGreen),
              title: const Text('Thông tin phân tích'),
              subtitle: Text(
                'AI dự đoán: $diseaseVietnameseName '
                'với độ tin cậy '
                '${confidence.toStringAsFixed(2)}%.',
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }
}
