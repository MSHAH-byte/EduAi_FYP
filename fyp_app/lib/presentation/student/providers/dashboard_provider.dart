import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/user_repository.dart';

class DashboardState {
  final List<Map<String, dynamic>> recentActivity;
  final bool isLoading;
  final String? userName;

  const DashboardState({
    this.recentActivity = const [],
    this.isLoading = false,
    this.userName,
  });

  DashboardState copyWith({
    List<Map<String, dynamic>>? recentActivity,
    bool? isLoading,
    String? userName,
  }) {
    return DashboardState(
      recentActivity: recentActivity ?? this.recentActivity,
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final UserRepository _repo = UserRepository();

  DashboardNotifier() : super(const DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      final profile = await _repo.getUserProfile();
      final activity = await _repo.getRecentActivity();
      state = state.copyWith(
        isLoading: false,
        userName: profile?['name'] ?? 'Student',
        recentActivity: activity,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);
