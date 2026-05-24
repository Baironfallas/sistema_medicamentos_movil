import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.aiBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.aiColor.withValues(alpha: 0.16),
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.aiColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Asistente de medicamentos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Consulta sobre tus medicamentos, horarios y recordatorios.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
