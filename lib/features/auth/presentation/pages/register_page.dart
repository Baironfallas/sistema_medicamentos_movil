import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';
import '../../data/auth_exception.dart';
import '../../data/auth_service.dart';
import '../../models/register_request.dart';
import '../validators/auth_validators.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_message.dart';
import '../widgets/primary_loading_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _identificationController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();
  final _firstLastNameController = TextEditingController();
  final _secondLastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _message;
  bool _isErrorMessage = true;

  @override
  void dispose() {
    _identificationController.dispose();
    _firstNameController.dispose();
    _secondNameController.dispose();
    _firstLastNameController.dispose();
    _secondLastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      final response = await _authService.register(
        RegisterRequest(
          identification: _identificationController.text.trim(),
          firstName: _firstNameController.text.trim(),
          secondName: _secondNameController.text.trim(),
          firstLastName: _firstLastNameController.text.trim(),
          secondLastName: _secondLastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      if (response.hasSession) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(MedicineReminderApp.homeRoute, (_) => false);
        return;
      }

      setState(() {
        _message =
            response.message ??
            'Registro completado. Ahora puedes iniciar sesión.';
        _isErrorMessage = false;
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushReplacementNamed(MedicineReminderApp.loginRoute);
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
      title: 'Crear cuenta',
      subtitle: 'Organiza tus medicamentos y recibe recordatorios a tiempo',
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
              controller: _identificationController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Identificación',
                hintText: '123456789',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) => AuthValidators.lengthBetween(
                value,
                'La identificación',
                min: 6,
                max: 20,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Primer nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => AuthValidators.lengthBetween(
                value,
                'El primer nombre',
                min: 2,
                max: 20,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _secondNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Segundo nombre',
                hintText: 'Opcional',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => AuthValidators.lengthBetween(
                value,
                'El segundo nombre',
                min: 2,
                max: 20,
                required: false,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstLastNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Primer apellido',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => AuthValidators.lengthBetween(
                value,
                'El primer apellido',
                min: 2,
                max: 30,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _secondLastNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Segundo apellido',
                hintText: 'Opcional',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => AuthValidators.lengthBetween(
                value,
                'El segundo apellido',
                min: 2,
                max: 30,
                required: false,
              ),
            ),
            const SizedBox(height: 16),
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Mínimo 8 caracteres',
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirmPassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () {
                    setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    );
                  },
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                final passwordError = AuthValidators.password(value);
                if (passwordError != null) {
                  return passwordError;
                }
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden.';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            PrimaryLoadingButton(
              label: 'Registrarme',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  '¿Ya tienes cuenta?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacementNamed(
                            MedicineReminderApp.loginRoute,
                          );
                        },
                  child: const Text('Inicia sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
