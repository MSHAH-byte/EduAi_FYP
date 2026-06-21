import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../shared/widgets/app_input_field.dart';
import '../../shared/widgets/app_primary_button.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreateAccount() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).signup(
        _nameController.text.trim(),
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
          SnackBar(content: Text(next.errorMessage ?? 'Signup failed')),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 14, color: AppColors.textPrimary),
                        const SizedBox(width: 6),
                        Text('Back', style: AppTextStyles.label.copyWith(
                          color: AppColors.textPrimary,
                        )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Title
                const Text('Create Account', style: AppTextStyles.heading),

                const SizedBox(height: 6),

                const Text(
                  'Join thousands of learners today',
                  style: AppTextStyles.body,
                ),

                const SizedBox(height: 32),

                // Full Name
                Text('Full Name', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AppInputField(
                  hint: 'Enter your name',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Name is required';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email
                Text('Email', style: AppTextStyles.label),
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

                // Password
                Text('Password', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AppInputField(
                  hint: 'Create password',
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

                const SizedBox(height: 20),

                // Confirm Password
                Text('Confirm Password', style: AppTextStyles.label),
                const SizedBox(height: 8),
                AppInputField(
                  hint: 'Repeat password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureConfirm,
                  controller: _confirmPasswordController,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Create Account button
                AppPrimaryButton(
                  label: 'Create Account',
                  isLoading: ref.watch(authProvider).status == AuthStatus.loading,
                  onTap: _onCreateAccount,
                ),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: AppTextStyles.body,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Login', style: AppTextStyles.link),
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
