import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color>? gradientColors;
  final bool loading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradientColors,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = gradientColors ?? [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.8)];

    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
