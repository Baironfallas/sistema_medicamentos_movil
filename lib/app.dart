import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_storage.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/chat/presentation/pages/chat_sessions_page.dart';
import 'features/medications/presentation/pages/medication_list_page.dart';
import 'features/medications/presentation/pages/today_intakes_page.dart';
import 'features/medications/services/intake_notification_manager.dart';

class MedicineReminderApp extends StatelessWidget {
  const MedicineReminderApp({super.key});

  static const loginRoute = '/login';
  static const registerRoute = '/register';
  static const homeRoute = '/home';
  static const medicationsRoute = '/medications';
  static const todayIntakesRoute = '/today-intakes';
  static const chatRoute = '/chat';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Medicamentos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: {
        loginRoute: (_) => const LoginPage(),
        registerRoute: (_) => const RegisterPage(),
        homeRoute: (_) => const HomePage(),
        medicationsRoute: (_) => const MedicationListPage(),
        todayIntakesRoute: (_) => const TodayIntakesPage(),
        chatRoute: (_) => const ChatSessionsPage(),
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthStorage _authStorage = AuthStorage();
  final IntakeNotificationManager _notificationManager =
      IntakeNotificationManager();

  late final Future<bool> _hasSession = _authStorage.hasSession();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _notificationManager.stop();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    final hasSession = await _hasSession;
    if (hasSession && mounted) {
      // Iniciar las notificaciones cuando el usuario está autenticado
      await _notificationManager.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data ?? false) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}
