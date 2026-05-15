import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../data/auth_service.dart';
import '../../models/auth_user.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();

  late final Future<AuthUser?> _user = _authService.getAuthenticatedUser();
  bool _isLoggingOut = false;

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Deseas salir de tu cuenta?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
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
              'No se pudo cerrar la sesión en el servidor, pero tu sesión local fue finalizada.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 40;

    return Scaffold(
      backgroundColor: const Color(0xFF06141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF06141B),
        foregroundColor: const Color(0xFFCCD0CF),
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'Sistema de Medicamentos',
          style: TextStyle(
            color: Color(0xFFCCD0CF),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _isLoggingOut ? null : _confirmLogout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFCCD0CF),
                    ),
                  )
                : const Icon(Icons.logout_outlined, color: Color(0xFFCCD0CF)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF06141B),
                  Color(0xFF11212D),
                  Color(0xFF253745),
                  Color(0xFF4A5C6A),
                ],
                stops: [0.0, 0.38, 0.72, 1.0],
              ),
            ),
          ),
          const Positioned(
            top: -70,
            right: -80,
            child: _AmbientShape(
              size: 220,
              color: Color(0xFF4A5C6A),
              opacity: 0.18,
            ),
          ),
          const Positioned(
            bottom: 80,
            left: -90,
            child: _AmbientShape(
              size: 260,
              color: Color(0xFF253745),
              opacity: 0.30,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(22, 28, 22, bottomPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 28 - bottomPadding,
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 28,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF11212D,
                                ).withOpacity(0.78),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(
                                    0xFFCCD0CF,
                                  ).withOpacity(0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.34),
                                    blurRadius: 34,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 78,
                                    height: 78,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF4A5C6A),
                                          Color(0xFF9BA8AB),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4A5C6A,
                                          ).withOpacity(0.28),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.medication_liquid_outlined,
                                      color: Color(0xFFCCD0CF),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    name == null || name.isEmpty
                                        ? 'Bienvenido'
                                        : 'Bienvenido, $name',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Color(0xFFCCD0CF),
                                          fontWeight: FontWeight.w800,
                                          height: 1.18,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Ya puedes gestionar tus medicamentos',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: const Color(0xFF9BA8AB),
                                          fontWeight: FontWeight.w500,
                                          height: 1.45,
                                        ),
                                  ),
                                  const SizedBox(height: 22),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF06141B,
                                      ).withOpacity(0.56),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF253745,
                                        ).withOpacity(0.9),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_active_outlined,
                                          color: Color(0xFFCCD0CF),
                                          size: 24,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Tu espacio de salud está listo para usar.',
                                            style: TextStyle(
                                              color: Color(0xFFCCD0CF),
                                              fontSize: 14,
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

class _AmbientShape extends StatelessWidget {
  const _AmbientShape({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.35),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}
