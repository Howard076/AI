import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

class AIChatScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String prediction;
  final double confidence;

  const AIChatScreen({
    super.key,
    required this.imageBytes,
    required this.prediction,
    required this.confidence,
  });

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  // ===============================================================
  // COLORS
  // ===============================================================

  static const Color backgroundColor = Color(0xFFF7FBF8);
  static const Color primaryGreen = Color(0xFF238252);
  static const Color darkText = Color(0xFF123D2F);
  static const Color secondaryText = Color(0xFF73817B);

  // ===============================================================
  // N8N WEBHOOK
  // ===============================================================

  static const String webhookUrl = 'http://localhost:5678/webhook/ai-chat';

  // ===============================================================
  // CONTROLLERS
  // ===============================================================

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  // ===============================================================
  // CHAT MESSAGE
  // ===============================================================

  final List<Map<String, dynamic>> _messages = [];

  bool _isSending = false;

  // ===============================================================
  // DISEASE NAME
  // ===============================================================

  String get diseaseName {
    switch (widget.prediction) {
      case 'Bacterial_Leaf_Blight':
        return 'Bacterial Leaf Blight';

      case 'Brown_Spot':
        return 'Brown Spot';

      case 'Healthy_Rice_Leaf':
        return 'Lá lúa khỏe mạnh';

      case 'Leaf_Blast':
        return 'Leaf Blast';

      case 'Leaf_scald':
        return 'Leaf Scald';

      case 'Sheath_Blight':
        return 'Sheath Blight';

      default:
        return widget.prediction.replaceAll('_', ' ');
    }
  }

  // ===============================================================
  // VIETNAMESE DISEASE NAME
  // ===============================================================

  String get diseaseVietnamese {
    switch (widget.prediction) {
      case 'Bacterial_Leaf_Blight':
        return 'Bệnh bạc lá';

      case 'Brown_Spot':
        return 'Bệnh đốm nâu';

      case 'Healthy_Rice_Leaf':
        return 'Lá lúa khỏe mạnh';

      case 'Leaf_Blast':
        return 'Bệnh đạo ôn ';

      case 'Leaf_scald':
        return 'Bệnh cháy lá';

      case 'Sheath_Blight':
        return 'Bệnh khô vằn';

      default:
        return diseaseName;
    }
  }

  // ===============================================================
  // SUGGESTED QUESTIONS
  // ===============================================================

  List<String> get suggestedQuestions {
    switch (widget.prediction) {
      case 'Bacterial_Leaf_Blight':
        return [
          'Bệnh bạc lá của lúa là bệnh gì?',
          'Cách trị bệnh bạc lá trên lúa ?',
          'Bệnh bạc lá trên lúa có nguy hiểm không?',
          'Cách phòng bệnh bạc lá cho lúa?',
        ];

      case 'Brown_Spot':
        return [
          'Bệnh đốm nâu trên lúa là bệnh gì?',
          'Cách trị bệnh đốm nâu cho lúa?',
          'Bệnh đốm nâu trên lúa có nguy hiểm không?',
          'Cách phòng bệnh đốm nâu cho lúa?',
        ];

      case 'Healthy_Rice_Leaf':
        return [
          'Làm sao để giữ lá lúa khỏe?',
          'Cách chăm sóc lúa khỏe mạnh?',
          'Làm sao phòng bệnh cho lúa?',
          'Nên bón phân cho lúa thế nào?',
        ];

      case 'Leaf_Blast':
        return [
          'Bệnh đạo ôn trên lúa là bệnh gì?',
          'Cách trị bệnh đạo ôn cho lúa?',
          'Bệnh đạo ôn trên lúa có nguy hiểm không?',
          'Cách phòng bệnh đạo ôn cho lúa?',
        ];

      case 'Leaf_scald':
        return [
          'Bệnh cháy lá trên lúa là bệnh gì?',
          'Cách trị bệnh cháy lá cho lúa?',
          'Bệnh cháy lá trên lúa có nguy hiểm không?',
          'Cách phòng bệnh cháy lá cho lúa?',
        ];

      case 'Sheath_Blight':
        return [
          'Bệnh khô vằn trên lúa là bệnh gì?',
          'Cách trị bệnh khô vằn cho lúa?',
          'Bệnh khô vằn trên lúa có nguy hiểm không?',
          'Cách phòng bệnh khô vằn cho lúa?',
        ];

      default:
        return [
          'Bệnh này là bệnh gì?',
          'Cách xử lý bệnh này?',
          'Cách phòng bệnh này?',
        ];
    }
  }

  // ===============================================================
  // INITIAL MESSAGE
  // ===============================================================

  String get aiIntroMessage {
    if (widget.prediction == 'Healthy_Rice_Leaf') {
      return 'Hình ảnh được AI nhận diện là lá lúa khỏe mạnh với độ tin cậy '
          '${widget.confidence.toStringAsFixed(2)}%. '
          'Bạn có thể hỏi tôi về cách chăm sóc và phòng bệnh cho cây lúa.';
    }

    return 'AI nhận diện hình ảnh có khả năng là $diseaseVietnamese '
        'với độ tin cậy ${widget.confidence.toStringAsFixed(2)}%. '
        'Bạn có thể hỏi tôi về bệnh này, cách xử lý hoặc cách phòng ngừa.';
  }

  // ===============================================================
  // INIT
  // ===============================================================

  @override
  void initState() {
    super.initState();

    _messages.add({'isUser': false, 'text': aiIntroMessage});
  }

  // ===============================================================
  // DISPOSE
  // ===============================================================

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===============================================================
  // SEND MESSAGE
  // ===============================================================

  Future<void> _sendMessage([String? suggestedQuestion]) async {
    if (_isSending) {
      return;
    }

    final message = (suggestedQuestion ?? _messageController.text).trim();

    if (message.isEmpty) {
      return;
    }

    _messageController.clear();

    setState(() {
      _messages.add({'isUser': true, 'text': message});

      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse(webhookUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'prediction': widget.prediction,
              'disease_name': diseaseName,
              'disease_vietnamese': diseaseVietnamese,
              'confidence': widget.confidence,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (!mounted) {
        return;
      }

      final answer = _extractAnswer(response);

      setState(() {
        _messages.add({'isUser': false, 'text': answer});

        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add({
          'isUser': false,
          'text':
              'Không thể kết nối đến trợ lý AI. '
              'Hãy kiểm tra n8n đang chạy và webhook đang được bật.',
        });

        _isSending = false;
      });

      _scrollToBottom();
    }
  }

  // ===============================================================
  // EXTRACT N8N ANSWER
  // ===============================================================

  String _extractAnswer(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'Workflow AI trả về lỗi '
          '${response.statusCode}. '
          'Vui lòng kiểm tra workflow n8n.';
    }

    if (response.body.trim().isEmpty) {
      return 'AI không trả về nội dung.';
    }

    try {
      final decoded = jsonDecode(response.body);

      // -----------------------------------------------------------
      // Trường hợp:
      // {
      //   "answer": "..."
      // }
      // -----------------------------------------------------------

      if (decoded is Map<String, dynamic>) {
        if (decoded['answer'] != null) {
          return decoded['answer'].toString();
        }

        // ---------------------------------------------------------
        // Trường hợp:
        // {
        //   "output": "..."
        // }
        // ---------------------------------------------------------

        if (decoded['output'] != null) {
          return decoded['output'].toString();
        }

        // ---------------------------------------------------------
        // Trường hợp:
        // {
        //   "response": "..."
        // }
        // ---------------------------------------------------------

        if (decoded['response'] != null) {
          return decoded['response'].toString();
        }

        // ---------------------------------------------------------
        // Trường hợp:
        // {
        //   "text": "..."
        // }
        // ---------------------------------------------------------

        if (decoded['text'] != null) {
          return decoded['text'].toString();
        }

        // ---------------------------------------------------------
        // Trường hợp AI Agent trả:
        // {
        //   "message": "..."
        // }
        // ---------------------------------------------------------

        if (decoded['message'] != null) {
          final message = decoded['message'];

          if (message is String) {
            return message;
          }

          if (message is Map<String, dynamic>) {
            if (message['content'] != null) {
              return message['content'].toString();
            }

            if (message['text'] != null) {
              return message['text'].toString();
            }
          }
        }
      }

      // -----------------------------------------------------------
      // Trường hợp n8n trả Array:
      //
      // [
      //   {
      //     "answer": "..."
      //   }
      // ]
      // -----------------------------------------------------------

      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;

        if (first is Map<String, dynamic>) {
          if (first['answer'] != null) {
            return first['answer'].toString();
          }

          if (first['output'] != null) {
            return first['output'].toString();
          }

          if (first['response'] != null) {
            return first['response'].toString();
          }

          if (first['text'] != null) {
            return first['text'].toString();
          }

          if (first['message'] != null) {
            return first['message'].toString();
          }
        }
      }

      // Nếu không nhận diện được JSON format
      return response.body;
    } catch (_) {
      // Nếu n8n trả plain text
      return response.body;
    }
  }

  // ===============================================================
  // SCROLL
  // ===============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
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

            Expanded(child: _buildChatArea()),

            _buildBottomInput(),
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

            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý AI',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Tư vấn bệnh cây lúa',
                  style: TextStyle(fontSize: 9.5, color: secondaryText),
                ),
              ],
            ),

            const Spacer(),

            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF46A66D),
              ),
            ),

            const SizedBox(width: 6),

            const Text(
              'AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // CHAT AREA
  // ===============================================================

  Widget _buildChatArea() {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(17, 8, 17, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetectedDisease(),

          const SizedBox(height: 18),

          _buildSuggestions(),

          const SizedBox(height: 20),

          ...List.generate(_messages.length, (index) {
            final message = _messages[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMessage(
                text: message['text'].toString(),
                isUser: message['isUser'] == true,
              ),
            );
          }),

          if (_isSending) ...[
            const SizedBox(height: 2),
            _buildTypingIndicator(),
          ],
        ],
      ),
    );
  }

  // ===============================================================
  // DETECTED DISEASE
  // ===============================================================

  Widget _buildDetectedDisease() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFFF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4EBDD)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: primaryGreen,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KẾT QUẢ PHÂN TÍCH',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: Color(0xFF599376),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  diseaseVietnamese,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Độ tin cậy ${widget.confidence.toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 9.5, color: secondaryText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SUGGESTIONS
  // ===============================================================

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gợi ý câu hỏi',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF71847B),
          ),
        ),

        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestedQuestions.map((question) {
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isSending ? null : () => _sendMessage(question),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD5E6DC)),
                ),
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF416C59),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===============================================================
  // MESSAGE
  // ===============================================================

  Widget _buildMessage({required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isUser ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(17),
              topRight: const Radius.circular(17),
              bottomLeft: Radius.circular(isUser ? 17 : 5),
              bottomRight: Radius.circular(isUser ? 5 : 17),
            ),
            border: isUser ? null : Border.all(color: const Color(0xFFE0ECE5)),
          ),
          child: isUser
              ? Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: Colors.white,
                  ),
                )
              : MarkdownBody(
                  data: text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: Color(0xFF536D61),
                    ),
                    strong: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF123D2F),
                    ),
                    h1: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123D2F),
                    ),
                    h2: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF123D2F),
                    ),
                    h3: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF123D2F),
                    ),
                    listBullet: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF238252),
                    ),
                    listIndent: 18,
                    blockSpacing: 8,
                  ),
                ),
        ),
      ),
    );
  }

  // ===============================================================
  // TYPING INDICATOR
  // ===============================================================

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE0ECE5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 7,
              height: 7,
              child: CircularProgressIndicator(
                strokeWidth: 1.7,
                color: primaryGreen,
              ),
            ),

            SizedBox(width: 9),

            Text(
              'AI đang trả lời...',
              style: TextStyle(fontSize: 10.5, color: secondaryText),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // BOTTOM INPUT
  // ===============================================================

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 10, 17, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46, maxHeight: 120),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFDDEAE2)),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isSending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 11.5, color: darkText),
                decoration: const InputDecoration(
                  hintText: 'Hỏi trợ lý AI...',
                  hintStyle: TextStyle(fontSize: 11, color: Color(0xFFA0AEA8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  if (!_isSending) {
                    _sendMessage();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 46,
            height: 46,
            child: ElevatedButton(
              onPressed: _isSending ? null : () => _sendMessage(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: const Color(0xFFA7C9B5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.arrow_upward_rounded, size: 21),
            ),
          ),
        ],
      ),
    );
  }
}
