import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomInput extends StatelessWidget {
  final String placeholder;
  final IconData icon;
  final bool isPassword;
  final bool showPassword;
  final VoidCallback? onTogglePassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final bool isFocused;
  final FocusNode? focusNode;

  const CustomInput({
    super.key,
    required this.placeholder,
    required this.icon,
    this.isPassword = false,
    this.showPassword = false,
    this.onTogglePassword,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.isFocused = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 60,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? colors.primary : colors.border,
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: isFocused ? [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: isFocused ? colors.primary : colors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: isPassword && !showPassword,
              keyboardType: keyboardType,
              onChanged: onChanged,
              validator: validator,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: colors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 22,
                color: colors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}
