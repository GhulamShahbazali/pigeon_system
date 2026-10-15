import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(const AuthState()) {
    on<AuthCheckRequestedEvent>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.loading));
      try {
        final outcome = await _repo.checkSession();
        switch (outcome.type) {
          case AuthOutcomeType.authenticated:
            emit(state.copyWith(
              status: AuthStatus.authenticated,
              name: outcome.name,
              email: outcome.email,
            ));
            break;
          case AuthOutcomeType.onboarding:
            emit(state.copyWith(
              status: AuthStatus.needsProfileSetup,
              name: outcome.name,
              email: outcome.email,
            ));
            break;
          case AuthOutcomeType.cancelled:
            emit(state.copyWith(status: AuthStatus.unauthenticated));
            break;
        }
      } catch (e) {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    });

    // Real Google sign-in: native account picker -> Firebase -> backend session.
    on<AuthGoogleSignInRequestedEvent>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.loading));
      try {
        final outcome = await _repo.signInWithGoogle();
        switch (outcome.type) {
          case AuthOutcomeType.authenticated:
            emit(state.copyWith(status: AuthStatus.authenticated));
            break;
          case AuthOutcomeType.onboarding:
            emit(state.copyWith(
              status: AuthStatus.needsProfileSetup,
              email: outcome.email,
              name: outcome.name,
            ));
            break;
          case AuthOutcomeType.cancelled:
            emit(state.copyWith(status: AuthStatus.unauthenticated));
            break;
        }
      } catch (e) {
        emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
      }
    });

    // Native picker already handles account choice; kept for UI compatibility.
    on<AuthAccountChosenEvent>((event, emit) {});

    on<AuthAppleSignInRequestedEvent>((event, emit) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Apple sign-in is not enabled yet.',
      ));
    });

    on<AuthProfileSubmittedEvent>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.loading));
      try {
        await _repo.completeSignup(
          name: event.name,
          username: event.username,
          language: event.language,
        );
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          name: event.name,
          username: event.username,
          language: event.language,
        ));
      } catch (e) {
        emit(state.copyWith(status: AuthStatus.error, errorMessage: e.toString()));
      }
    });

    on<AuthLogoutRequestedEvent>((event, emit) async {
      await _repo.signOut();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    });
  }
}
