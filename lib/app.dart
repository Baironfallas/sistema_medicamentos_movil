import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_storage.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';

class MedicineReminderApp extends StatelessWidget {
  const MedicineReminderApp({super.key});

  static const loginRoute = '/login';
  static const registerRoute = '/register';
  static const homeRoute = '/home';

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

  late final Future<bool> _hasSession = _authStorage.hasSession();

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
