import 'package:flutter/material.dart';

import '../../../../app.dart';
import '../../../../core/theme/app_colors.dart';
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

  static const double _fieldSpacing = 10;
  static const double _columnSpacing = 12;

  InputDecoration _fieldDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    final borderRadius = BorderRadius.circular(12);
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(color: AppColors.border, width: 1.0),
    );

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      border: enabledBorder,
      enabledBorder: enabledBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _responsiveFieldRow({
    required bool useTwoColumns,
    required Widget first,
    required Widget second,
  }) {
    if (!useTwoColumns) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          first,
          const SizedBox(height: _fieldSpacing),
          second,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: _columnSpacing),
        Expanded(child: second),
      ],
    );
  }

  Widget _identificationField() {
    return TextFormField(
      controller: _identificationController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Identificación',
        hintText: '123456789',
        prefixIcon: Icons.badge_outlined,
      ),
      validator: (value) => AuthValidators.lengthBetween(
        value,
        'La identificación',
        min: 6,
        max: 20,
      ),
    );
  }

  Widget _firstNameField() {
    return TextFormField(
      controller: _firstNameController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Primer nombre',
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) => AuthValidators.lengthBetween(
        value,
        'El primer nombre',
        min: 2,
        max: 20,
      ),
    );
  }

  Widget _secondNameField() {
    return TextFormField(
      controller: _secondNameController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Segundo nombre',
        hintText: 'Opcional',
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) => AuthValidators.lengthBetween(
        value,
        'El segundo nombre',
        min: 2,
        max: 20,
        required: false,
      ),
    );
  }

  Widget _firstLastNameField() {
    return TextFormField(
      controller: _firstLastNameController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Primer apellido',
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) => AuthValidators.lengthBetween(
        value,
        'El primer apellido',
        min: 2,
        max: 30,
      ),
    );
  }

  Widget _secondLastNameField() {
    return TextFormField(
      controller: _secondLastNameController,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Segundo apellido',
        hintText: 'Opcional',
        prefixIcon: Icons.person_outline,
      ),
      validator: (value) => AuthValidators.lengthBetween(
        value,
        'El segundo apellido',
        min: 2,
        max: 30,
        required: false,
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Correo electrónico',
        hintText: 'juan.perez@gmail.com',
        prefixIcon: Icons.email_outlined,
      ),
      validator: AuthValidators.email,
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Contraseña',
        hintText: 'Mínimo 8 caracteres',
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          color: AppColors.textSecondary,
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
    );
  }

  Widget _confirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        labelText: 'Confirmar contraseña',
        prefixIcon: Icons.lock_outline,
        suffixIcon: IconButton(
          color: AppColors.textSecondary,
          tooltip: _obscureConfirmPassword
              ? 'Mostrar contraseña'
              : 'Ocultar contraseña',
          onPressed: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
    );
  }

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
      visualRefresh: true,
      maxWidth: 720,
      headerHeight: 68,
      headerIconSize: 32,
      headerTitleSpacing: 14,
      titleFormSpacing: 14,
      cardPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      headerLabel: 'Registro seguro para tu salud',
      scrollBottomPadding: 52,
      darkDecorativeBackground: true,
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth > 650;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_message != null) ...[
                  AuthMessage(message: _message!, isError: _isErrorMessage),
                  const SizedBox(height: 14),
                ],
                _sectionTitle('Datos personales'),
                _identificationField(),
                const SizedBox(height: _fieldSpacing),
                _responsiveFieldRow(
                  useTwoColumns: useTwoColumns,
                  first: _firstNameField(),
                  second: _secondNameField(),
                ),
                const SizedBox(height: _fieldSpacing),
                _responsiveFieldRow(
                  useTwoColumns: useTwoColumns,
                  first: _firstLastNameField(),
                  second: _secondLastNameField(),
                ),
                const SizedBox(height: 14),
                _sectionTitle('Datos de acceso'),
                _emailField(),
                const SizedBox(height: _fieldSpacing),
                _responsiveFieldRow(
                  useTwoColumns: useTwoColumns,
                  first: _passwordField(),
                  second: _confirmPasswordField(),
                ),
                const SizedBox(height: 18),
                PrimaryLoadingButton(
                  label: 'Registrarme',
                  isLoading: _isLoading,
                  onPressed: _submit,
                  useGradient: false,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes cuenta?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
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
            );
          },
        ),
      ),
    );
  }
}
