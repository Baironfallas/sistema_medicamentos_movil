import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../controllers/medication_controller.dart';
import '../widgets/info_banner.dart';

class MedicationFormPage extends StatefulWidget {
  const MedicationFormPage({
    super.key,
    required this.controller,
    this.medication,
  });

  final MedicationController controller;
  final Medication? medication;

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _totalController = TextEditingController();
  final _startDateController = TextEditingController();

  List<String> _schedules = [];
  String? _scheduleError;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final medication = widget.medication;
    if (medication != null) {
      _nameController.text = medication.name;
      _doseController.text = medication.dose ?? '';
      _descriptionController.text = medication.description ?? '';
      _quantityController.text = medication.quantityPerIntake.toString();
      _totalController.text = medication.totalPills.toString();
      _startDateController.text = medication.startDate;
      _schedules = List<String>.from(medication.scheduleHours);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _totalController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final initialDate = _parseDate(_startDateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDateController.text = _formatDate(picked);
    });
  }

  Future<void> _addSchedule() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked == null) {
      return;
    }

    final formatted = _formatTime(picked);
    if (_schedules.contains(formatted)) {
      return;
    }

    setState(() {
      _schedules = [..._schedules, formatted]..sort();
      _scheduleError = null;
    });
  }

  void _removeSchedule(String hour) {
    setState(() {
      _schedules = _schedules.where((item) => item != hour).toList();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_schedules.isEmpty) {
      setState(() => _scheduleError = 'Agrega al menos un horario.');
      return;
    }

    final quantity = _parseNum(_quantityController.text);
    final total = _parseNum(_totalController.text);

    final draft = MedicationDraft(
      name: _nameController.text.trim(),
      dose: _doseController.text.trim(),
      description: _descriptionController.text.trim(),
      quantityPerIntake: quantity,
      totalPills: total,
      startDate: _startDateController.text.trim(),
      schedules: _schedules,
    );

    final controller = widget.controller;
    final success = _isEditing
        ? await controller.updateMedication(widget.medication!.id, draft)
        : await controller.createMedication(draft);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    final error = controller.medicationsError;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
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
        title: Text(_isEditing ? 'Editar medicamento' : 'Nuevo medicamento'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              if (widget.controller.medicationsError != null) ...[
                InfoBanner(message: widget.controller.medicationsError!),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Datos del medicamento'),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Color(0xFFCCD0CF)),
                      decoration: _fieldDecoration('Nombre'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es obligatorio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _doseController,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Color(0xFFCCD0CF)),
                      decoration: _fieldDecoration('Dosis (opcional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      style: const TextStyle(color: Color(0xFFCCD0CF)),
                      decoration: _fieldDecoration('Descripcion (opcional)'),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Cantidad y fechas'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            readOnly: _isEditing,
                            style: const TextStyle(color: Color(0xFFCCD0CF)),
                            decoration: _fieldDecoration('Cantidad por toma'),
                            validator: (value) {
                              if (!_isPositiveInteger(value)) {
                                return 'Ingresa una cantidad valida.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _totalController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            readOnly: _isEditing,
                            style: const TextStyle(color: Color(0xFFCCD0CF)),
                            decoration: _fieldDecoration('Total de pastillas'),
                            validator: (value) {
                              if (!_isPositiveInteger(value)) {
                                return 'Ingresa un total valido.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      onTap: _isEditing ? null : _pickStartDate,
                      style: const TextStyle(color: Color(0xFFCCD0CF)),
                      decoration: _fieldDecoration(
                        'Fecha de inicio',
                      ).copyWith(suffixIcon: const Icon(Icons.event)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Selecciona la fecha de inicio.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Horarios de toma'),
                    Text(
                      'Frecuencia: ${_schedules.length} al dia.',
                      style: const TextStyle(color: Color(0xFF9BA8AB)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final hour in _schedules)
                          Chip(
                            label: Text(hour),
                            onDeleted: _isEditing
                                ? null
                                : () => _removeSchedule(hour),
                          ),
                        if (!_isEditing)
                          ActionChip(
                            label: const Text('Agregar horario'),
                            onPressed: _addSchedule,
                            avatar: const Icon(Icons.add, size: 18),
                          ),
                      ],
                    ),
                    if (_scheduleError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _scheduleError!,
                        style: const TextStyle(color: Color(0xFFFFB4AB)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.controller.isSaving ? null : _submit,
                        child: widget.controller.isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditing
                                    ? 'Guardar cambios'
                                    : 'Crear medicamento',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF11212D).withValues(alpha: 0.75),
      labelStyle: const TextStyle(color: Color(0xFF9BA8AB)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF253745)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF9BA8AB), width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF253745)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFCCD0CF),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _isPositiveInteger(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    return number != null && number > 0;
  }

  int _parseNum(String raw) {
    return int.tryParse(raw.trim()) ?? 0;
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
