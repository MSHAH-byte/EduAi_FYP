import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/datasources/remote/fastapi_service.dart';
import '../../shared/widgets/app_primary_button.dart';
import '../../shared/widgets/app_input_field.dart';
import '../../shared/widgets/loading_overlay.dart';
import 'slides_result_screen.dart';
import 'notes_result_screen.dart';
import 'quiz_result_screen.dart';

enum GenerateType { slides, notes, quiz }

class GenerateScreen extends StatefulWidget {
  final GenerateType type;
  const GenerateScreen({super.key, required this.type});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final _topicController = TextEditingController();
  final _api = FastApiService();
  bool _isLoading = false;

  String get _title {
    switch (widget.type) {
      case GenerateType.slides: return 'Generate Slides';
      case GenerateType.notes: return 'Generate Notes';
      case GenerateType.quiz: return 'Generate Quiz';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case GenerateType.slides: return Icons.slideshow_rounded;
      case GenerateType.notes: return Icons.notes_rounded;
      case GenerateType.quiz: return Icons.assignment_outlined;
    }
  }

  String get _hint {
    switch (widget.type) {
      case GenerateType.slides: return 'e.g. Object Oriented Programming';
      case GenerateType.notes: return 'e.g. Data Structures';
      case GenerateType.quiz: return 'e.g. Database Management Systems';
    }
  }

  Future<void> _generate() async {
    if (_topicController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final topic = _topicController.text.trim();
      Map<String, dynamic> result;
      switch (widget.type) {
        case GenerateType.slides:
          result = await _api.generateSlides(topic, 5);
          if (mounted) Navigator.push(context,
            MaterialPageRoute(builder: (_) => SlidesResultScreen(data: result)));
          break;
        case GenerateType.notes:
          result = await _api.generateNotes(topic);
          if (mounted) Navigator.push(context,
            MaterialPageRoute(builder: (_) => NotesResultScreen(data: result)));
          break;
        case GenerateType.quiz:
          result = await _api.generateQuiz(topic, 5);
          if (mounted) Navigator.push(context,
            MaterialPageRoute(builder: (_) => QuizResultScreen(data: result)));
          break;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_title, style: AppTextStyles.subheading),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(_icon, color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              Center(child: Text(_title, style: AppTextStyles.heading)),
              const SizedBox(height: 8),
              Center(child: Text('Enter a topic to get started', style: AppTextStyles.body)),
              const SizedBox(height: 40),
              Text('Topic', style: AppTextStyles.label),
              const SizedBox(height: 8),
              AppInputField(
                hint: _hint,
                prefixIcon: Icons.lightbulb_outline_rounded,
                controller: _topicController,
              ),
              const SizedBox(height: 32),
              AppPrimaryButton(
                label: _isLoading ? 'Generating...' : 'Generate',
                isLoading: false,
                onTap: _generate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
