import 'package:equatable/equatable.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  choosingAccount,
  needsProfileSetup,
  authenticated,
  loading,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? email;
  final String? name;
  final String? username;
  final String? language;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.email,
    this.name,
    this.username,
    this.language,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? email,
    String? name,
    String? username,
    String? language,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      language: language ?? this.language,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        email,
        name,
        username,
        language,
        errorMessage,
      ];
}
