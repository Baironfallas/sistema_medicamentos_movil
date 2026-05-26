import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/medication.dart';
import '../controllers/medication_controller.dart';
import '../widgets/info_banner.dart';
import 'medication_form_page.dart';

class MedicationListPage extends StatefulWidget {
  const MedicationListPage({super.key});

  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  late final MedicationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MedicationController();
    _controller.loadMedications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm({Medication? medication}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            MedicationFormPage(controller: _controller, medication: medication),
      ),
    );

    if (saved == true) {
      await _controller.loadMedications();
    }
  }

  Future<void> _confirmDelete(Medication medication) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Eliminar medicamento',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Deseas eliminar "${medication.name}"? Esta accion no se puede deshacer.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final success = await _controller.deleteMedication(medication.id);
    if (!mounted) {
      return;
    }

    if (!success && _controller.medicationsError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_controller.medicationsError!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _controller.loadMedications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          if (_controller.medicationsError != null) ...[
            InfoBanner(message: _controller.medicationsError!),
            const SizedBox(height: 24),
          ],
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.medication_outlined,
                  color: AppColors.textSecondary,
                  size: 56,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Aun no tienes medicamentos registrados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Agrega tu primer medicamento para empezar con los recordatorios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                  ),
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar medicamento'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final schedules = medication.scheduleHours;
    final scheduleText = schedules.isEmpty
        ? 'Sin horarios'
        : schedules.join(', ');

    Widget actionButton({
      required IconData icon,
      required String tooltip,
      required Color color,
      required VoidCallback? onPressed,
    }) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: color, size: 18),
        ),
      );
    }

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
                  AppColors.primary.withValues(alpha: 0.85),
                  AppColors.aiColor.withValues(alpha: 0.7),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (medication.dose != null &&
                              medication.dose!.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Dosis: ${medication.dose}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    actionButton(
                      tooltip: 'Editar',
                      icon: Icons.edit_outlined,
                      color: AppColors.secondary,
                      onPressed: () => _openForm(medication: medication),
                    ),
                    const SizedBox(width: 8),
                    actionButton(
                      tooltip: 'Eliminar',
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      onPressed: _controller.isDeleting
                          ? null
                          : () => _confirmDelete(medication),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                infoRow(
                  icon: Icons.schedule_outlined,
                  text: scheduleText,
                ),
                const SizedBox(height: 8),
                infoRow(
                  icon: Icons.medication_liquid_outlined,
                  text:
                      'Cantidad: ${medication.quantityPerIntake} | Total: ${medication.totalPills}',
                ),
                if (medication.pillsRemaining != null ||
                    medication.daysRemaining != null) ...[
                  const SizedBox(height: 8),
                  infoRow(
                    icon: Icons.inventory_2_outlined,
                    text:
                        'Restantes: ${medication.pillsRemaining ?? '-'} | Dias: ${medication.daysRemaining ?? '-'}',
                  ),
                ],
                const SizedBox(height: 8),
                infoRow(
                  icon: Icons.event_outlined,
                  text: 'Inicio: ${medication.startDate}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          'Mis medicamentos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _controller.isLoadingMedications
                ? null
                : _controller.loadMedications,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingMedications) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (_controller.medications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _controller.loadMedications,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
              children: [
                if (_controller.medicationsError != null) ...[
                  InfoBanner(message: _controller.medicationsError!),
                  const SizedBox(height: 16),
                ],
                for (final medication in _controller.medications)
                  _buildMedicationCard(medication),
              ],
            ),
          );
        },
      ),
    );
  }
}
