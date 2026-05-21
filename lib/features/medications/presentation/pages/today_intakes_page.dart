import 'package:flutter/material.dart';

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
                  color: Color(0xFF9BA8AB),
                  size: 56,
                ),
                const SizedBox(height: 14),
                const Text(
                  'No tienes tomas programadas para hoy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFCCD0CF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cuando existan horarios pendientes los veras aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF9BA8AB)),
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
        ? 'Confirmada'
        : status == 'omitted'
        ? 'Omitida'
        : 'Pendiente';
    final statusColor = status == 'taken'
        ? const Color(0xFF86EFAC)
        : status == 'omitted'
        ? const Color(0xFFFFB4AB)
        : const Color(0xFFFCD34D);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF11212D).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF253745).withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  intake.medicationName,
                  style: const TextStyle(
                    color: Color(0xFFCCD0CF),
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
                  color: statusColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
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
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                color: Color(0xFF9BA8AB),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                intake.timeLabel ?? 'Horario pendiente',
                style: const TextStyle(color: Color(0xFF9BA8AB)),
              ),
              if (intake.dateLabel != null) ...[
                const SizedBox(width: 10),
                Text(
                  intake.dateLabel!,
                  style: const TextStyle(color: Color(0xFF9BA8AB)),
                ),
              ],
            ],
          ),
          if (intake.canConfirm) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _controller.isConfirming
                    ? null
                    : () => _confirmIntake(intake),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirmar toma'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmIntake(MedicationIntake intake) async {
    final success = await _controller.confirmIntake(intake.id);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06141B),
        foregroundColor: const Color(0xFFCCD0CF),
        title: const Text('Tomas de hoy'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _controller.isLoadingIntakes
                ? null
                : _controller.loadTodayIntakes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoadingIntakes) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.todayIntakes.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
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
