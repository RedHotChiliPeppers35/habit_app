import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:habit_app/core/models/contants.dart';

class HabitChatPage extends StatefulWidget {
  const HabitChatPage({super.key});

  @override
  State<HabitChatPage> createState() => _HabitChatPageState();
}

class _HabitChatPageState extends State<HabitChatPage> {
  final ChatUser user = ChatUser(id: "1", firstName: "You");
  final ChatUser bot = ChatUser(id: "2", firstName: "HabitBot");
  final List<ChatMessage> messages = [];
  late final GenerativeModel model;
  late final ChatSession chat;

  bool isTyping = false; // 👈 Added typing state

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception("GEMINI_API_KEY not found. Did you create .env?");
    }

    model = GenerativeModel(
      model: "gemini-2.5-pro",
      apiKey: apiKey,
      systemInstruction: Content.text(
        "You are HabitBot, a friendly motivational coach inside a habit tracking app. "
        "Encourage users to stay consistent, celebrate their progress, and give practical suggestions. "
        "Keep responses short and conversational, ending each message with an encouraging tip.",
      ),
    );

    chat = model.startChat();
  }

  Future<void> _handleSend(ChatMessage m) async {
    setState(() {
      messages.insert(0, m);
      isTyping = true; // 👈 Start typing animation
    });

    try {
      final response = await chat.sendMessage(Content.text(m.text));
      final reply = response.text ?? "I'm here to help you stay consistent!";

      setState(() {
        isTyping = false; // 👈 Stop animation
        messages.insert(
          0,
          ChatMessage(user: bot, createdAt: DateTime.now(), text: reply),
        );
      });
    } catch (e) {
      setState(() {
        isTyping = false;
        messages.insert(
          0,
          ChatMessage(
            user: bot,
            createdAt: DateTime.now(),
            text:
                "⚠️ HabitBot is taking a short break — please try again soon.",
          ),
        );
      });
    }
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _TypingDot(),
            SizedBox(width: 3),
            _TypingDot(delay: 200),
            SizedBox(width: 3),
            _TypingDot(delay: 400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        elevation: 4,
        leading: const CloseButton(color: Colors.white),
        title: const Text(
          "Habit Coach",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                DashChat(
                  currentUser: user,
                  onSend: _handleSend,
                  messages: messages,
                  inputOptions: InputOptions(
                    alwaysShowSend: false,
                    inputTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),

                    inputDecoration: InputDecoration(
                      hintText: "Ask HabitBot anything...",

                      hintStyle: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Colors.white,
                      ),
                      filled: true,

                      fillColor: AppColors.accentRed,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),

                        borderSide: BorderSide.none,
                      ),
                    ),

                    sendButtonBuilder:
                        (onSend) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.accentDark,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                              onPressed: onSend,
                            ),
                          ),
                        ),
                  ),

                  messageOptions: MessageOptions(
                    currentUserContainerColor: AppColors.accentRed.withOpacity(
                      0.9,
                    ),
                    currentUserTextColor: Colors.white,
                    containerColor: Colors.grey.shade200,
                    textColor: Colors.black87,
                    borderRadius: 20,
                    messagePadding: const EdgeInsets.all(10),
                    showTime: true,
                  ),
                ),

                // 👇 Typing animation overlay
                if (isTyping)
                  Positioned(bottom: 75, left: 10, child: _buildTypingBubble()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({this.delay = 0});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(widget.delay / 900, 1.0, curve: Curves.easeInOut),
        ),
      ),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: AppColors.accentDark.withOpacity(
            0.9,
          ), // 👈 Darker, high contrast
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDark.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
