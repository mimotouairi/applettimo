import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? theme.primaryColor : theme.dividerColor,
          width: isFocused ? 2.0 : 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isFocused ? theme.primaryColor : theme.hintColor,
          ),
          const SizedBox(width: 12),
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
                color: theme.textTheme.bodyLarge?.color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  color: theme.hintColor.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: theme.hintColor,
              ),
            ),
        ],
      ),
    );
  }
}
