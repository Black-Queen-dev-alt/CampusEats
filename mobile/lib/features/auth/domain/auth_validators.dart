/// Validation côté client (le serveur reste l'autorité : erreurs 422).
class AuthValidators {
  static String? requiredField(String value, String message) =>
      value.trim().isEmpty ? message : null;

  static String? email(String value) {
    final text = value.trim();
    if (text.isEmpty) return "L'email est requis";
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : "Format d'email invalide";
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Le mot de passe est requis';
    if (value.length < 8) return 'Au moins 8 caractères';
    return null;
  }

  static String? fullName(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Le nom complet est requis';
    if (text.length < 2) return 'Au moins 2 caractères';
    return null;
  }

  static String? confirmPassword(String password, String confirm) =>
      password == confirm ? null : 'Les mots de passe ne correspondent pas';
}
