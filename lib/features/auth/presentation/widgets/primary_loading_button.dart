import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class PrimaryLoadingButton extends StatelessWidget {
  const PrimaryLoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.useGradient = false,
    this.gradientColors,
    this.textColor = Colors.white,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final bool useGradient;
  final List<Color>? gradientColors;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (useGradient) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                gradientColors ?? const [AppColors.primary, AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: EdgeInsets.zero,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isLoading
                  ? SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: textColor,
                      ),
                    )
                  : Text(
                      label,
                      key: const ValueKey('label'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: isLoading ? null : onPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label, key: const ValueKey('label')),
      ),
    );
  }
}
