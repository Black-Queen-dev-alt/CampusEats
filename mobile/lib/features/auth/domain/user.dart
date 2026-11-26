import 'package:equatable/equatable.dart';

/// Rôles exacts renvoyés par l'API : "etudiant", "personnel", "admin".
enum UserRole {
  etudiant,
  personnel,
  admin;

  /// Retourne null si l'API envoie un rôle inconnu.
  static UserRole? fromApi(String? value) {
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }
}

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;

  @override
  List<Object?> get props => [id, email, fullName, role];
}
