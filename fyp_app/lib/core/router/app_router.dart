import 'package:flutter/material.dart';
import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/signup_screen.dart';
import '../../presentation/student/screens/dashboard_screen.dart';
import '../../presentation/student/screens/chat_screen.dart';

abstract class AppRouter {
  static const String splash    = '/';
  static const String login     = '/login';
  static const String signup    = '/signup';
  static const String dashboard = '/dashboard';
  static const String chat      = '/chat';

  static Map<String, WidgetBuilder> get routes => {
    splash:    (_) => const SplashScreen(),
    login:     (_) => const LoginScreen(),
    signup:    (_) => const SignupScreen(),
    dashboard: (_) => const DashboardScreen(),
    chat:      (_) => const ChatScreen(),
  };
}
