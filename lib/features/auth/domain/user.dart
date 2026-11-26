// Domain model for a user
class User {
  final String id;
  final String email;
  final String role; // "student", "staff", "admin"

  const User({required this.id, required this.email, required this.role});
}
