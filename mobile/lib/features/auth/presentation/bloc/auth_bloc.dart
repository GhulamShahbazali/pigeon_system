import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthCheckRequestedEvent>((event, emit) {
      // Simulate splash check
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    });

    on<AuthGoogleSignInRequestedEvent>((event, emit) {
      emit(state.copyWith(status: AuthStatus.choosingAccount));
    });

    on<AuthAppleSignInRequestedEvent>((event, emit) {
      emit(state.copyWith(
        status: AuthStatus.needsProfileSetup,
        email: 'user@apple.com',
      ));
    });

    on<AuthAccountChosenEvent>((event, emit) {
      emit(state.copyWith(
        status: AuthStatus.needsProfileSetup,
        email: event.email,
        name: 'Ahmed Raza',
      ));
    });

    on<AuthProfileSubmittedEvent>((event, emit) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        name: event.name,
        username: event.username,
        language: event.language,
      ));
    });

    on<AuthLogoutRequestedEvent>((event, emit) {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    });
  }
}
