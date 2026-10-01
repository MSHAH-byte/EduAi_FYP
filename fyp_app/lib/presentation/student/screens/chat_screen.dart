import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/widgets/action_chip_item.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickOptions = [
    'Generate Quiz',
    'Create Notes',
    'Summarize Topic',
  ];

  final List<Map<String, dynamic>> _actionChips = [
    {
      'label': 'Generate Quiz',
      'icon': Icons.quiz_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'label': 'Summarize',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'label': 'Create Notes',
      'icon': Icons.notes_rounded,
      'color': Color(0xFF10B981),
    },
    {
      'label': 'Ask Question',
      'icon': Icons.help_outline_rounded,
      'color': Color(0xFFEC4899),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text.trim());
    _inputController.clear();
    _scrollToBottom();
  }

  Future<void> _pickAndUploadDocument() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the file picker.')),
        );
      }
      return;
    }

    if (result == null || result.files.single.path == null) return;

    final picked = result.files.single;
    final extension = (picked.extension ?? '').toLowerCase();

    if (extension != 'pdf' && extension != 'docx') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF or DOCX file.')),
        );
      }
      return;
    }

    await ref.read(chatProvider.notifier).uploadDocument(
      File(picked.path!),
      picked.name,
    );

    _scrollToBottom();
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.upload_file_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Upload Document', style: AppTextStyles.label),
                subtitle: const Text('PDF or DOCX', style: AppTextStyles.hint),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    ref.listen(chatProvider, (previous, next) {
      if (previous?.isTyping == true && !next.isTyping) {
        _scrollToBottom();
      }
      if (previous?.isUploading == true && !next.isUploading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI Assistant', style: AppTextStyles.subheading),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('Online', style: AppTextStyles.hint),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => ref.read(chatProvider.notifier).clearHistory(),
                  child: const Icon(Icons.refresh_rounded,
                      color: AppColors.textHint, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(chatState.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          // Messages list
          Expanded(
            child: chatState.isLoadingHistory
                ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              itemCount: chatState.messages.length +
                  ((chatState.isTyping || chatState.isUploading) ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator
                if ((chatState.isTyping || chatState.isUploading) &&
                    index == chatState.messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TypingDot(delay: 0),
                            const SizedBox(width: 4),
                            _TypingDot(delay: 200),
                            const SizedBox(width: 4),
                            _TypingDot(delay: 400),
                            const SizedBox(width: 8),
                            Text(
                              chatState.isUploading
                                  ? 'Reading ${chatState.uploadingFileName ?? "document"}...'
                                  : 'AI is typing...',
                              style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final msg = chatState.messages[index];

                // Quick option chips under first message
                if (index == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ChatBubble(
                          message: msg.message,
                          isAi: msg.isAi,
                          time: msg.time,
                        ),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets.only(left: 4, bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickOptions.map((option) {
                            return GestureDetector(
                              onTap: () => _sendMessage(option),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: AppColors.border),
                                ),
                                child: Text(option,
                                    style: AppTextStyles.label),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: msg.fileName != null
                      ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints:
                            const BoxConstraints(maxWidth: 200),
                            child: Text(msg.fileName!,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.label),
                          ),
                        ],
                      ),
                    ),
                  )
                      : ChatBubble(
                    message: msg.message,
                    isAi: msg.isAi,
                    time: msg.time,
                  ),
                );
              },
            ),
          ),

          // Scrollable action chips
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _actionChips.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChipItem(
                      label: chip['label'],
                      icon: chip['icon'],
                      color: chip['color'],
                      onTap: () => _sendMessage(chip['label']),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                // Attachment button
                GestureDetector(
                  onTap: chatState.isUploading ? null : _showUploadSheet,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: chatState.isUploading
                          ? AppColors.textHint
                          : AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask a question or choose an action...',
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: AppColors.surface, size: 18),
                  ),
                ),
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
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.textHint,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}