import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final String userId;
  final String? email;
  final bool needsRegistration;

  const AuthAuthenticated({
    required this.token,
    required this.userId,
    this.email,
    this.needsRegistration = true,
  });

  @override
  List<Object?> get props => [token, userId, email, needsRegistration];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class OtpSent extends AuthState {
  final String collegeId;

  const OtpSent({required this.collegeId});

  @override
  List<Object> get props => [collegeId];
}
