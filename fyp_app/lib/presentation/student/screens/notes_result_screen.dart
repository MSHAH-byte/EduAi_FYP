import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class NotesResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const NotesResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final keyPoints = data['key_points'] as List<dynamic>;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(data['topic'] ?? 'Notes', style: AppTextStyles.subheading),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary', style: AppTextStyles.subheading),
                  const SizedBox(height: 8),
                  Text(data['summary'] ?? '', style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Key Points', style: AppTextStyles.subheading),
            const SizedBox(height: 10),
            ...keyPoints.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(point.toString(), style: AppTextStyles.body)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
            const Text('Detailed Notes', style: AppTextStyles.subheading),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(data['detailed_notes'] ?? '', style: AppTextStyles.body),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
