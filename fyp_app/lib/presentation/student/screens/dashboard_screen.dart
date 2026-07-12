import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../shared/widgets/dashboard_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'generate_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.menu_book_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello, ${dashboardState.userName ?? 'Student'}',
                                style: AppTextStyles.heading,
                              ),
                              const SizedBox(width: 6),
                              const Text('👋', style: TextStyle(fontSize: 24)),
                            ],
                          ),
                          const Text(
                            'What would you like to create today?',
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.textSecondary, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // CREATE CONTENT label
              Text(
                'CREATE CONTENT',
                style: AppTextStyles.label.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textHint,
                ),
              ),

              const SizedBox(height: 12),

              // Feature cards
              DashboardCard(
                icon: Icons.slideshow_rounded,
                title: 'Generate Slides',
                subtitle: 'Create lecture slides from a topic or document',
                iconBackground: const Color(0xFFEEF2FF),
                iconColor: const Color(0xFF4A6CF7),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GenerateScreen(type: GenerateType.slides))),
              ),
              const SizedBox(height: 10),

              DashboardCard(
                icon: Icons.notes_rounded,
                title: 'Generate Notes',
                subtitle: 'Create structured study notes and summaries',
                iconBackground: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF97316),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GenerateScreen(type: GenerateType.notes))),
              ),
              const SizedBox(height: 10),

              DashboardCard(
                icon: Icons.assignment_outlined,
                title: 'Generate Assessment',
                subtitle: 'Create quizzes, assignments, and exams',
                iconBackground: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF22C55E),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const GenerateScreen(type: GenerateType.quiz))),
              ),

              const SizedBox(height: 28),

              // OR divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: AppTextStyles.label),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 20),

              // Start Chat with AI card
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Chat with AI',
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ask anything, anytime',
                            style: AppTextStyles.hint,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.chat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Chat',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 14, color: AppColors.surface),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}
