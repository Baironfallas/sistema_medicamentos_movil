import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
      subtitle: 'Accede para gestionar tus medicamentos y recordatorios',
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
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                hintText: 'juan.perez@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
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
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Password123',
                prefixIcon: const Icon(Icons.lock_outline),
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
                  ),
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 22),
            PrimaryLoadingButton(
              label: 'Iniciar sesión',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  '¿No tienes cuenta?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
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
