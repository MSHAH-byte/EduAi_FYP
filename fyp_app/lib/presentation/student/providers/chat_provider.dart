import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/remote/fastapi_service.dart';
import '../../../data/repositories/user_repository.dart';

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
  final bool isLoadingHistory;
  final String? error;
  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isLoadingHistory = false,
    this.error,
  });
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    bool? isLoadingHistory,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error ?? this.error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final FastApiService _api = FastApiService();
  final UserRepository _repo = UserRepository();
  final List<Map<String, dynamic>> _history = [];

  ChatNotifier() : super(const ChatState());

  Future<void> loadHistory() async {
    if (state.isLoadingHistory) return;

    state = state.copyWith(isLoadingHistory: true);
    try {
      final history = await _repo.getChatHistory();
      if (history.isEmpty) {
        const welcome = ChatMessage(
          message: 'Hello! 👋 I can help you generate slides, notes, quizzes, and more. Choose an action above or type your question below.',
          isAi: true,
          time: '06:05 PM',
        );
        state = state.copyWith(
          messages: [welcome],
          isLoadingHistory: false,
        );
      } else {
        final messages = history.map((m) => ChatMessage(
          message: m['message'] ?? '',
          isAi: m['isAi'] ?? true,
          time: m['time'] ?? '',
        )).toList();
        
        // Sync history for AI context
        _history.clear();
        for (final m in history) {
          _history.add({
            'role': m['isAi'] == true ? 'assistant' : 'user',
            'content': m['message'] ?? '',
          });
        }
        
        state = state.copyWith(
          messages: messages,
          isLoadingHistory: false,
        );
      }
    } catch (e) {
      // Fail gracefully — show welcome message if Firestore fails
      state = state.copyWith(
        messages: [
          const ChatMessage(
            message: 'Hello! 👋 I can help you generate slides, notes, quizzes, and more.',
            isAi: true,
            time: '06:05 PM',
          ),
        ],
        isLoadingHistory: false,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final time = _currentTime();
    final userMessage = ChatMessage(
      message: text.trim(),
      isAi: false,
      time: time,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      error: null,
    );
    _history.add({'role': 'user', 'content': text.trim()});
    await _repo.saveChatMessage(
      message: text.trim(),
      isAi: false,
      time: time,
    );
    try {
      final response = await _api.chat(text.trim(), _history);
      _history.add({'role': 'assistant', 'content': response});
      final aiTime = _currentTime();
      await _repo.saveChatMessage(
        message: response,
        isAi: true,
        time: aiTime,
      );
      final aiMessage = ChatMessage(
        message: response,
        isAi: true,
        time: aiTime,
      );
      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isTyping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isTyping: false,
        error: 'Failed to get response. Check your connection.',
      );
    }
  }

  Future<void> clearHistory() async {
    await _repo.clearChatHistory();
    state = const ChatState();
    await loadHistory();
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
