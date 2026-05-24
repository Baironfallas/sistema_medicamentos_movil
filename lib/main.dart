import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicios de notificaciones
  final notificationService = LocalNotificationService();
  await notificationService.initialize();

  runApp(const MedicineReminderApp());
}
