import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const QuizResultScreen({super.key, required this.data});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final Map<int, String> _selectedAnswers = {};
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.data['questions'] as List<dynamic>;
    int score = 0;
    if (_submitted) {
      for (int i = 0; i < questions.length; i++) {
        if (_selectedAnswers[i] == questions[i]['correct_answer']) score++;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.data['topic'] ?? 'Quiz', style: AppTextStyles.subheading),
      ),
      body: Column(
        children: [
          if (_submitted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryLight,
              child: Text(
                'Score: $score / ${questions.length}',
                style: AppTextStyles.subheading.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final options = q['options'] as List<dynamic>;
                final correct = q['correct_answer'];
                final selected = _selectedAnswers[index];

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
                      Text('Q${index + 1}. ${q['question']}',
                        style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 10),
                      ...options.map((option) {
                        Color? bgColor;
                        if (_submitted) {
                          if (option == correct) bgColor = Colors.green.shade50;
                          else if (option == selected && option != correct) bgColor = Colors.red.shade50;
                        }
                        return GestureDetector(
                          onTap: _submitted ? null : () => setState(() => _selectedAnswers[index] = option.toString()),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: bgColor ?? (selected == option ? AppColors.primaryLight : AppColors.background),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected == option ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Text(option.toString(), style: AppTextStyles.body),
                          ),
                        );
                      }),
                      if (_submitted && q['explanation'] != null) ...[
                        const SizedBox(height: 8),
                        Text('💡 ${q['explanation']}',
                          style: AppTextStyles.hint.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          if (!_submitted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => setState(() => _submitted = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Submit Quiz',
                    style: TextStyle(color: AppColors.surface, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
