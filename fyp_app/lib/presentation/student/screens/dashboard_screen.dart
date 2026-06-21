import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../shared/widgets/dashboard_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Hello, ${dashboardState.userName ?? 'Student'}',
                              style: AppTextStyles.heading),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'What would you like to create today?',
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                  // Logout button
                  GestureDetector(
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      Navigator.pushReplacementNamed(context, AppRouter.login);
                    },
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
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
                onTap: () {},
              ),
              const SizedBox(height: 10),

              DashboardCard(
                icon: Icons.notes_rounded,
                title: 'Generate Notes',
                subtitle: 'Create structured study notes and summaries',
                onTap: () {},
              ),
              const SizedBox(height: 10),

              DashboardCard(
                icon: Icons.assignment_outlined,
                title: 'Generate Assessment',
                subtitle: 'Create quizzes, assignments, and exams',
                onTap: () {},
              ),
              const SizedBox(height: 10),

              DashboardCard(
                icon: Icons.upload_file_rounded,
                title: 'Upload Document',
                subtitle: 'Upload PDF or DOC to extract topics and notes',
                onTap: () {},
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

              // RECENT ACTIVITY label
              Text(
                'RECENT ACTIVITY',
                style: AppTextStyles.label.copyWith(
                  letterSpacing: 1.2,
                  color: AppColors.textHint,
                ),
              ),

              const SizedBox(height: 12),

              // Recent activity items
              if (dashboardState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (dashboardState.recentActivity.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No recent activity yet', style: AppTextStyles.hint),
                  ),
                )
              else
                ...dashboardState.recentActivity.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentActivityItem(
                    icon: _iconForType(item['type'] ?? ''),
                    title: item['title'] ?? '',
                    time: _formatTime(item['createdAt']),
                  ),
                )),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'slides': return Icons.slideshow_rounded;
      case 'notes': return Icons.notes_rounded;
      case 'quiz': return Icons.assignment_outlined;
      case 'upload': return Icons.upload_file_rounded;
      default: return Icons.star_rounded;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final dt = (timestamp as dynamic).toDate() as DateTime;
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _RecentActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _RecentActivityItem({
    required this.icon,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(time, style: AppTextStyles.hint.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
