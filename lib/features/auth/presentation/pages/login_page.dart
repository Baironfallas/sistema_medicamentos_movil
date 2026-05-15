import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../data/auth_exception.dart';
import '../../data/auth_service.dart';
import '../../models/login_request.dart';
import '../validators/auth_validators.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_message.dart';
import '../widgets/primary_loading_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _message;
  bool _isErrorMessage = true;

  InputDecoration _fieldDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final borderRadius = BorderRadius.circular(12);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFF0D1F23).withOpacity(0.68),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Color(0xFF2D4A53)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Color(0xFF2D4A53), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Color(0xFF69818D), width: 1.5),
      ),
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
      prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.60)),
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await _authService.login(
        LoginRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Inicio de sesión correcto.';
        _isErrorMessage = false;
      });

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(MedicineReminderApp.homeRoute, (_) => false);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = error.message;
        _isErrorMessage = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormLayout(
      title: 'Iniciar sesión',
      subtitle: 'Organiza tus medicamentos y recibe recordatorios a tiempo.',
      welcomeText: 'Bienvenido de nuevo',
      supportingText: 'Cuida tu salud de forma simple y segura.',
      headerLabel: 'Recordatorios inteligentes para tu salud',
      visualRefresh: true,
      headerHeight: 102,
      headerIconSize: 36,
      headerTitleSpacing: 22,
      titleFormSpacing: 28,
      darkDecorativeBackground: true,
      showTitle: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message != null) ...[
              AuthMessage(message: _message!, isError: _isErrorMessage),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration(
                labelText: 'Correo electrónico',
                hintText: 'juan.perez@gmail.com',
                prefixIcon: Icons.email_outlined,
              ),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration(
                labelText: 'Contraseña',
                hintText: 'Password123',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.white.withOpacity(0.60),
                  ),
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 20),
            PrimaryLoadingButton(
              label: 'Iniciar sesión',
              isLoading: _isLoading,
              onPressed: _submit,
              useGradient: true,
              gradientColors: const [Color(0xFF3D6B7A), Color(0xFF89A8B2)],
              textColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '¿No tienes cuenta?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF80CBC4),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacementNamed(
                            MedicineReminderApp.registerRoute,
                          );
                        },
                  child: const Text('Regístrate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
