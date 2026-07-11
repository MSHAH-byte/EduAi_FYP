import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SlidesResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const SlidesResultScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final slides = data['slides'] as List<dynamic>;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(data['topic'] ?? 'Slides', style: AppTextStyles.subheading),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: slides.length,
        itemBuilder: (context, index) {
          final slide = slides[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text('${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(slide['title'] ?? '',
                        style: AppTextStyles.subheading),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(slide['content'] ?? '', style: AppTextStyles.body),
                const SizedBox(height: 10),
                ...(slide['bullet_points'] as List<dynamic>).map((point) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 16)),
                        Expanded(child: Text(point.toString(), style: AppTextStyles.body)),
                      ],
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}
