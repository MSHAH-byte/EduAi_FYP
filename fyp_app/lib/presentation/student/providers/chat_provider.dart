import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String message;
  final bool isAi;
  final String time;

  const ChatMessage({
    required this.message,
    required this.isAi,
    required this.time,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: [
    const ChatMessage(
      message: 'Hello! 👋 I can help you generate slides, notes, quizzes, and more. Choose an action above or type your question below.',
      isAi: true,
      time: '06:05 PM',
    ),
  ]));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      message: text.trim(),
      isAi: false,
      time: _currentTime(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    // TODO: replace with FastAPI call
    await Future.delayed(const Duration(seconds: 2));

    final aiMessage = ChatMessage(
      message: _getMockResponse(text.trim()),
      isAi: true,
      time: _currentTime(),
    );

    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isTyping: false,
    );
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getMockResponse(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('quiz') || lower.contains('assessment')) {
      return 'Sure! I can generate a quiz for you. Please provide the topic and number of questions you\'d like.';
    } else if (lower.contains('notes') || lower.contains('summarize')) {
      return 'I\'ll create structured notes for you. What topic or document would you like me to summarize?';
    } else if (lower.contains('slides')) {
      return 'Great! I can generate lecture slides. What topic should the slides cover?';
    } else if (lower.contains('upload')) {
      return 'You can upload a PDF or DOC file and I\'ll extract key topics and generate content from it.';
    } else {
      return 'I\'m here to help! You can ask me to generate quizzes, notes, slides, or upload a document for analysis.';
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
