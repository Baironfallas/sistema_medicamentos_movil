import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_service.dart';
import '../../models/auth_user.dart';
import '../../../medications/services/intake_notification_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();

  late final Future<AuthUser?> _user = _authService.getAuthenticatedUser();
  int _selectedDestination = 0;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    IntakeNotificationManager().start();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Cerrar sesion',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Deseas salir de tu cuenta?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    if (shouldLogout ?? false) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final serverLogoutSucceeded = await _authService.logout();
    await IntakeNotificationManager().stop();

    if (!mounted) {
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      MedicineReminderApp.loginRoute,
      (_) => false,
    );

    if (!serverLogoutSucceeded) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo cerrar la sesion en el servidor, pero tu sesion local fue finalizada.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _openDestination(int index) async {
    final routes = [
      MedicineReminderApp.medicationsRoute,
      MedicineReminderApp.todayIntakesRoute,
      MedicineReminderApp.chatRoute,
    ];

    setState(() => _selectedDestination = index);
    await Navigator.of(context).pushNamed(routes[index]);

    if (mounted) {
      setState(() => _selectedDestination = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 74,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleSpacing: 20,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(0.5),
          child: SizedBox(
            height: 0.5,
            child: ColoredBox(color: Color(0xFFE0E0E0)),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Medora',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tu salud organizada',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : const Icon(Icons.logout_outlined, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: const Color(0xFF00BFA5).withOpacity(0.14),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return TextStyle(
                color: isSelected
                    ? const Color(0xFF00BFA5)
                    : const Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final isSelected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: isSelected
                    ? const Color(0xFF00BFA5)
                    : const Color(0xFF9CA3AF),
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _selectedDestination,
            height: 72,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: _openDestination,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.medication_outlined),
                selectedIcon: Icon(Icons.medication),
                label: 'Medicamentos',
              ),
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.notifications_active),
                label: 'Tomas de hoy',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.smart_toy_outlined),
                label: 'Asistente',
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(color: AppColors.background),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 34, 22, 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 66,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: FutureBuilder<AuthUser?>(
                          future: _user,
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            final name = user?.displayName;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00BFA5),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF00BFA5),
                                                Color(0xFF00897B),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.medication_liquid_outlined,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          name == null || name.isEmpty
                                              ? 'Bienvenido'
                                              : 'Bienvenido, $name',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF1A1A2E),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Ya puedes gestionar tus medicamentos y recordatorios',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF0FBF9),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .notifications_active_outlined,
                                                color: Color(0xFF00BFA5),
                                                size: 18,
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Tu espacio de salud esta listo para acompanar tus rutinas diarias.',
                                                  style: TextStyle(
                                                    color: Color(0xFF374151),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
