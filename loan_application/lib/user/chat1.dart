import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

void main() {
  runApp(const WonderamiChatApp());
}

class WonderamiChatApp extends StatelessWidget {
  const WonderamiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wondarmi Loan Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

// Model Class for Chat Messages
class ChatMessage {
  final String text;
  final bool isUser;
  final String? source;
  final Map<String, dynamic>? entities;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.source,
    this.entities,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Dynamic Base URL based on Environment / Platform
  String get baseUrl {
  if (kIsWeb) {
    return 'http://10.49.240.67:8000';
  } else if (Platform.isAndroid) {
    // 10.0.2.2 maps directly to host machine's localhost on Android Emulator
    return 'http://10.49.240.67:8000'; 
  } else if (Platform.isIOS) {
    return 'http://10.49.240.67:8000';
  } else {
    // Desktop (Windows, macOS, Linux)9
    return 'http://10.49.240.67:8000';
  }
}

  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late String _userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Unique User ID per App Session
    _userId = const Uuid().v4();

    // Initial Welcome Message
    _messages.add(
      ChatMessage(
        text:
            "မင်္ဂလာပါ ခင်ဗျာ! Wondarmi မှ ကြိုဆိုပါတယ်။ စိုက်ပျိုးရေး၊ အသေးစားစီးပွားရေး နှင့် လူသုံးကုန်ချေးငွေများအကြောင်း မေးမြန်းနိုင်ပါတယ်။",
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String messageText) async {
    final trimmedText = messageText.trim();
    if (trimmedText.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: trimmedText, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/chat'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'user_id': _userId, 'message': trimmedText}),
          )
          .timeout(const Duration(seconds: 360));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  data['answer'] ??
                  "ကျေးဇူးပြု၍ ခဏစောင့်ပြီး ပြန်လည်မေးမြန်းပေးပါ။",
              isUser: false,
              source: data['source'],
              entities: data['entities'] != null
                  ? Map<String, dynamic>.from(data['entities'])
                  : null,
            ),
          );
        });
      } else {
        _showErrorMessage(
          "Server မှ ပြန်လည်ဖြေကြားရာတွင် အမှားအယွင်းရှိနေပါသည်။ (Error: ${response.statusCode})",
        );
      }
    } catch (e) {
      _showErrorMessage(
        "Backend Server သို့ ချိတ်ဆက်၍ မရပါခင်ဗျာ။ (URL: $baseUrl ကို စစ်ဆေးပေးပါ)",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _resetSession() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/reset-session'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'user_id': _userId}),
      );
      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage(
            text:
                "Chat History ကို Reset ပြုလုပ်ပြီးပါပြီ ခင်ဗျာ။ အသစ်ပြန်လည် မေးမြန်းနိုင်ပါပြီ။",
            isUser: false,
          ),
        );
      });
    } catch (e) {
      _showErrorMessage("Session reset ပြုလုပ်ခြင်း မအောင်မြင်ပါ။");
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(text: "⚠️ $message", isUser: false));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        shadowColor: Colors.blue.withOpacity(0.2),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wondarmi Loan Assistant',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Online • AI Microfinance Bot',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset Conversation',
            onPressed: _resetSession,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 16.0,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildChatBubble(_messages[index]);
              },
            ),
          ),
          if (_isLoading) _buildCoolTypingIndicator(),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade600 : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : const Color(0xFF0A2540),
                fontSize: 14.5,
                height: 1.45,
                fontWeight: isUser ? FontWeight.normal : FontWeight.w400,
              ),
            ),
            if (!isUser &&
                message.entities != null &&
                message.entities!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Wrap(
                  spacing: 8,
                  children: message.entities!.entries.map((e) {
                    return Text(
                      "${e.key}: ${e.value}",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoolTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 14, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Wondarmi AI",
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            TypingDotsAnimation(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                style: const TextStyle(color: Color(0xFF0A2540)),
                decoration: InputDecoration(
                  hintText: 'မေးခွန်းများ ရိုက်ထည့်ပါ...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade300,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F8FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.blue.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.blue.shade400,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade600,
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _sendMessage(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingDotsAnimation extends StatefulWidget {
  const TypingDotsAnimation({super.key});

  @override
  State<TypingDotsAnimation> createState() => _TypingDotsAnimationState();
}

class _TypingDotsAnimationState extends State<TypingDotsAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final double opacity = ((_controller.value * 3 - index) % 1.0)
                .clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade600.withOpacity(opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
