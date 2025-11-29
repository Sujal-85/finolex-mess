import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // Track if user has completed registration
  bool _registrationCompleted = false;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<OtpRequested>(_onOtpRequested);
    on<RegistrationCompleted>(_onRegistrationCompleted);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    // Check for persisted token
    await Future.delayed(const Duration(seconds: 2)); // Simulate splash delay
    emit(AuthUnauthenticated()); // Default to unauthenticated for now
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      if (event.otp == '1234') {
        // Check if registration is already completed
        if (_registrationCompleted) {
          emit(
            AuthAuthenticated(
              token: 'fake_token',
              userId: 'student_1',
              email: event.collegeId,
              needsRegistration: false,
            ),
          );
        } else {
          // For demo purposes, we'll set needsRegistration to true initially
          // In a real app, this would come from the API response
          emit(
            AuthAuthenticated(
              token: 'fake_token',
              userId: 'student_1',
              email: event.collegeId,
              needsRegistration: true,
            ),
          );
        }
      } else {
        emit(const AuthFailure(message: 'Invalid OTP'));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(seconds: 1));
    emit(AuthUnauthenticated());
  }

  Future<void> _onOtpRequested(
    OtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(OtpSent(collegeId: event.collegeId));
    } catch (e) {
      emit(AuthFailure(message: e.toString()));
    }
  }

  Future<void> _onRegistrationCompleted(
    RegistrationCompleted event,
    Emitter<AuthState> emit,
  ) async {
    _registrationCompleted = true;
    // Emit the current state but with needsRegistration set to false
    if (state is AuthAuthenticated) {
      final authState = state as AuthAuthenticated;
      emit(
        AuthAuthenticated(
          token: authState.token,
          userId: authState.userId,
          email: authState.email,
          needsRegistration: false,
        ),
      );
    }
  }
}
