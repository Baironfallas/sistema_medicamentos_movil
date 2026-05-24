import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/medication_intake.dart';
import '../controllers/medication_controller.dart';
import 'info_banner.dart';

class PendingIntakesAlert extends StatefulWidget {
  const PendingIntakesAlert({super.key});

  @override
  State<PendingIntakesAlert> createState() => _PendingIntakesAlertState();
}

class _PendingIntakesAlertState extends State<PendingIntakesAlert> {
  late final MedicationController _controller;
  late final Future<void> _loadIntakes;

  @override
  void initState() {
    super.initState();
    _controller = MedicationController();
    _loadIntakes = _controller.loadTodayIntakes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _updateIntakeStatus(
    MedicationIntake intake,
    String status,
  ) async {
    final success = await _controller.updateIntakeStatus(intake.id, status);
    if (!mounted) {
      return;
    }

    if (success) {
      final statusLabel = status == 'taken' ? 'tomada' : 'omitida';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${intake.medicationName} marcada como $statusLabel'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: status == 'taken'
                ? AppColors.success
                : AppColors.error,
          ),
        );
    } else if (_controller.intakesError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_controller.intakesError!),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadIntakes,
      builder: (context, snapshot) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            if (_controller.isLoadingIntakes) {
              return const Column(
                children: [
                  SizedBox(height: 16),
                  LinearProgressIndicator(),
                ],
              );
            }

            if (_controller.intakesError != null) {
              return Column(
                children: [
                  const SizedBox(height: 16),
                  InfoBanner(message: _controller.intakesError!),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _controller.loadTodayIntakes(),
                          child: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            final pendingIntakes = _controller.todayIntakes
                .where((intake) => intake.status.toLowerCase() == 'pending')
                .toList();

            if (pendingIntakes.isEmpty) {
              return const SizedBox(height: 8);
            }

            return Column(
              children: [
                const SizedBox(height: 16),
                _buildPendingIntakesCard(pendingIntakes),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPendingIntakesCard(List<MedicationIntake> intakes) {
    final firstIntake = intakes.first;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.12),
            AppColors.warning.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active,
                  color: AppColors.warning,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicamentos por tomar',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${intakes.length} ${intakes.length == 1 ? 'toma pendiente' : 'tomas pendientes'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstIntake.medicationName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      firstIntake.timeLabel ?? 'Horario pendiente',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (intakes.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${intakes.length - 1} mas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _controller.isConfirming
                      ? null
                      : () => _updateIntakeStatus(firstIntake, 'omitted'),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Omitida'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _controller.isConfirming
                      ? null
                      : () => _updateIntakeStatus(firstIntake, 'taken'),
                  icon: _controller.isConfirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text(
                    'Tomada',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
