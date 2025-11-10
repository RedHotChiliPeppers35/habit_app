import 'dart:ui';

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

  bool isTyping = false;

  // 🔹 Quick suggestion prompts
  final List<String> _quickPrompts = const [
    "Help me build a simple morning routine.",
    "Give me motivation to stay consistent today.",
    "How can I get back on track after missing a few days?",
    "Suggest small habits to improve my health.",
    "How do I stay focused on one habit at a time?",
  ];

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
      isTyping = true;
    });

    try {
      final response = await chat.sendMessage(Content.text(m.text));
      final reply = response.text ?? "I'm here to help you stay consistent!";

      setState(() {
        isTyping = false;
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

  // 🔹 Called when a quick suggestion chip is tapped
  void _sendQuickPrompt(String prompt) {
    final msg = ChatMessage(
      user: user,
      createdAt: DateTime.now(),
      text: prompt,
    );
    _handleSend(msg);
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.65), width: 1.2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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

  Widget _buildQuickSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick suggestions",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _quickPrompts.map((prompt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _sendQuickPrompt(prompt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.85),
                                Colors.white.withOpacity(0.55),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.8),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.sparkles,
                                size: 14,
                                color: AppColors.accentRed,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                prompt,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        elevation: 0,
        leading: const CloseButton(color: Colors.white),
        title: const Text("Habit Coach", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundCream,
              AppColors.backgroundCream.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Glass background
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withOpacity(0.14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 1.1,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Content inside glass
                        Column(
                          children: [
                            _buildQuickSuggestions(),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Stack(
                                children: [
                                  DashChat(
                                    currentUser: user,
                                    onSend: _handleSend,
                                    messages: messages,
                                    inputOptions: InputOptions(
                                      alwaysShowSend: false,
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
                                        fillColor: AppColors.accentRed
                                            .withOpacity(0.95),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      inputTextStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      sendButtonBuilder:
                                          (onSend) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  AppColors.surfaceDark,
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
                                      borderRadius: 20,
                                      messagePadding: const EdgeInsets.all(10),
                                      showTime: true,
                                      currentUserContainerColor: AppColors
                                          .accentRed
                                          .withOpacity(0.9),
                                      currentUserTextColor: Colors.white,
                                      containerColor: Colors.white.withOpacity(
                                        0.85,
                                      ),
                                      textColor: Colors.black87,
                                    ),
                                  ),

                                  if (isTyping)
                                    Positioned(
                                      bottom: 80,
                                      left: 10,
                                      child: _buildTypingBubble(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "HabitBot is here to guide you. Tap a suggestion or ask anything ✨",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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
          color: AppColors.accentRed.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.surfaceDark.withOpacity(0.7),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
