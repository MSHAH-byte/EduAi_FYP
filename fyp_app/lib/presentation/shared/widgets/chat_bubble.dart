import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isAi;
  final String? time;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isAi,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment:
            isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAi ? AppColors.surface : AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isAi ? 4 : 16),
                bottomRight: Radius.circular(isAi ? 16 : 4),
              ),
              border: isAi ? Border.all(color: AppColors.border) : null,
            ),
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(
                color: isAi ? AppColors.textPrimary : AppColors.surface,
              ),
            ),
          ),
          if (time != null) ...[
            const SizedBox(height: 4),
            Text(time!, style: AppTextStyles.hint.copyWith(fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
