import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../shared/widgets/app_input_field.dart';
import '../../shared/widgets/app_primary_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.pushReplacementNamed(context, AppRouter.dashboard);
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? 'Login failed')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Book icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                const Text('Welcome Back', style: AppTextStyles.heading),

                const SizedBox(height: 8),

                const Text(
                  'Login to continue learning',
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 40),

                // Email label + field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email', style: AppTextStyles.label),
                ),
                const SizedBox(height: 8),
                AppInputField(
                  hint: 'Enter email',
                  prefixIcon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password label + forgot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Password', style: AppTextStyles.label),
                    GestureDetector(
                      onTap: () {}, // TODO: forgot password
                      child: const Text('Forgot?', style: AppTextStyles.link),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppInputField(
                  hint: 'Enter password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  controller: _passwordController,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Login button
                AppPrimaryButton(
                  label: 'Login',
                  isLoading: ref.watch(authProvider).status == AuthStatus.loading,
                  onTap: _onLogin,
                ),

                const SizedBox(height: 24),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: AppTextStyles.body,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                          context, AppRouter.signup),
                      child: const Text('Sign up', style: AppTextStyles.link),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
