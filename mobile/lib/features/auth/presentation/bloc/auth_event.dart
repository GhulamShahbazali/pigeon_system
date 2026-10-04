import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequestedEvent extends AuthEvent {}

class AuthGoogleSignInRequestedEvent extends AuthEvent {}

class AuthAppleSignInRequestedEvent extends AuthEvent {}

class AuthAccountChosenEvent extends AuthEvent {
  final String email;
  const AuthAccountChosenEvent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthProfileSubmittedEvent extends AuthEvent {
  final String name;
  final String username;
  final String language;

  const AuthProfileSubmittedEvent({
    required this.name,
    required this.username,
    required this.language,
  });

  @override
  List<Object?> get props => [name, username, language];
}

class AuthLogoutRequestedEvent extends AuthEvent {}
