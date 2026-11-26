part of 'auth_bloc.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);

  String get role => user.role;

  @override
  List<Object?> get props => [user];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthFailure extends AuthState {
  final Map<String, String> fieldErrors;
  const AuthFailure({required this.fieldErrors});

  @override
  List<Object?> get props => [fieldErrors];
}
