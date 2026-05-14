class AuthValidators {
  AuthValidators._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
  );

  static String? requiredText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredText(value, 'El correo electrónico');
    if (requiredError != null) {
      return requiredError;
    }

    if (!_emailRegex.hasMatch(value!.trim())) {
      return 'Ingresa un correo electrónico válido.';
    }

    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredText(value, 'La contraseña');
    if (requiredError != null) {
      return requiredError;
    }

    if (value!.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }

    return null;
  }

  static String? lengthBetween(
    String? value,
    String fieldName, {
    required int min,
    required int max,
    bool required = true,
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return required ? '$fieldName es obligatorio.' : null;
    }

    if (text.length < min || text.length > max) {
      return '$fieldName debe tener entre $min y $max caracteres.';
    }

    return null;
  }
}
