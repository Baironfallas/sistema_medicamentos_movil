import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/medication_intake.dart';
import '../controllers/medication_controller.dart';
import '../widgets/info_banner.dart';

class TodayIntakesPage extends StatefulWidget {
  const TodayIntakesPage({super.key});

  @override
  State<TodayIntakesPage> createState() => _TodayIntakesPageState();
}

class _TodayIntakesPageState extends State<TodayIntakesPage> {
  late final MedicationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MedicationController();
    _controller.loadTodayIntakes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _controller.loadTodayIntakes,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          if (_controller.intakesError != null) ...[
            InfoBanner(message: _controller.intakesError!),
            const SizedBox(height: 24),
          ],
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.textSecondary,
                  size: 56,
                ),
                const SizedBox(height: 14),
                const Text(
                  'No tienes tomas programadas para hoy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cuando existan horarios pendientes los veras aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeCard(MedicationIntake intake) {
    final status = intake.status.toLowerCase();
    final statusLabel = status == 'taken'
        ? 'Tomada'
        : status == 'omitted'
        ? 'Omitida'
        : 'Pendiente';
    final statusColor = status == 'taken'
        ? AppColors.success
        : status == 'omitted'
        ? AppColors.error
        : AppColors.warning;

    Widget infoRow({required IconData icon, required String text}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    Widget statPill({
      required IconData icon,
      required String label,
      required String value,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 14),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final scheduledText = intake.dateLabel != null
        ? '${intake.timeLabel ?? 'Horario pendiente'} · ${intake.dateLabel}'
        : (intake.timeLabel ?? 'Horario pendiente');

    final respondedTime = intake.respondedTimeLabel;
    final respondedDate = intake.respondedDateLabel;
    final respondedText = respondedTime == null
        ? null
        : (respondedDate == null
            ? respondedTime
            : '$respondedTime · $respondedDate');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  statusColor.withValues(alpha: 0.9),
                  statusColor.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        status == 'taken'
                            ? Icons.check_circle_outline
                            : status == 'omitted'
                            ? Icons.cancel_outlined
                            : Icons.schedule_outlined,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        intake.medicationName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                infoRow(
                  icon: Icons.schedule_outlined,
                  text: scheduledText,
                ),
                if (respondedText != null) ...[
                  const SizedBox(height: 8),
                  infoRow(
                    icon: Icons.check_circle_outline,
                    text: 'Respondida: $respondedText',
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    statPill(
                      icon: Icons.medication_liquid_outlined,
                      label: 'Cantidad',
                      value: '${intake.quantityTaken ?? 0}',
                    ),
                    statPill(
                      icon: Icons.inventory_2_outlined,
                      label: 'Restantes',
                      value: '${intake.remainingPills ?? '-'}',
                    ),
                  ],
                ),
                if (intake.canConfirm) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                          ),
                          onPressed: _controller.isConfirming
                              ? null
                              : () => _updateIntakeStatus(intake, 'omitted'),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Omitida'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                          ),
                          onPressed: _controller.isConfirming
                              ? null
                              : () => _updateIntakeStatus(intake, 'taken'),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Tomada'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateIntakeStatus(
    MedicationIntake intake,
    String status,
  ) async {
    final success = await _controller.updateIntakeStatus(intake.id, status);
    if (!mounted) {
      return;
    }

    if (!success && _controller.intakesError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_controller.intakesError!),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.border.withValues(alpha: 0.1),
        title: const Text(
          'Tomas de hoy',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _controller.isLoadingIntakes
                ? null
                : _controller.loadTodayIntakes,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingIntakes) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_controller.todayIntakes.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _controller.loadTodayIntakes,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                if (_controller.intakesError != null) ...[
                  InfoBanner(message: _controller.intakesError!),
                  const SizedBox(height: 16),
                ],
                for (final intake in _controller.todayIntakes)
                  _buildIntakeCard(intake),
              ],
            ),
          );
        },
      ),
    );
  }
}
