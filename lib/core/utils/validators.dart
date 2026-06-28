/// Validadores reutilizables para los formularios de la app.
/// Devuelven `null` si el valor es válido, o un mensaje de error si no.
class Validators {
  Validators._();

  // Solo letras (incluye acentos y ñ), espacios, guiones y apóstrofes.
  static final RegExp _nameRegex = RegExp(r"^[a-zA-ZáéíóúüÁÉÍÓÚÜñÑ\s'-]+$");
  static final RegExp _emailRegex =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre';
    if (v.length < 3) return 'El nombre es muy corto';
    if (v.length > 50) return 'El nombre es muy largo';
    if (!_nameRegex.hasMatch(v)) {
      return 'El nombre solo puede contener letras';
    }
    return null;
  }

  static String? company(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa el nombre de la empresa';
    if (v.length < 2) return 'El nombre es muy corto';
    if (v.length > 60) return 'El nombre es muy largo';
    return null;
  }

  static String? inviteCode(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa el código de invitación';
    if (v.length < 4) return 'Código demasiado corto';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(v)) return 'Correo no válido';
    return null;
  }

  /// Validación de contraseña para inicio de sesión: solo presencia y largo.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Validación reforzada para el registro: exige letra y número.
  static String? strongPassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Debe incluir al menos una letra';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != original) return 'Las contraseñas no coinciden';
    return null;
  }
}
