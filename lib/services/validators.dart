// File: lib/utils/validators.dart

/// Valida che un campo di testo non sia vuoto.
String? requiredValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Questo campo è obbligatorio';
  }
  return null;
}

/// Valida il formato di un indirizzo email.
String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Inserisci un indirizzo email';
  }
  final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  if (!emailRegex.hasMatch(value)) {
    return 'Inserisci un\'email valida';
  }
  return null;
}

/// Valida la lunghezza minima di una password.
String? passwordValidator(String? value, {int minLength = 6}) {
  if (value == null || value.isEmpty) {
    return 'Inserisci una password';
  }
  if (value.length < minLength) {
    return 'La password non valida';
  }
  return null;
}