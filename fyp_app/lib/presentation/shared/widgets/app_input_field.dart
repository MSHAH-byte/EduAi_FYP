import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppInputField extends StatelessWidget {
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AppInputField({
    super.key,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppColors.textHint, size: 20),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
