import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String collegeId;
  final String otp;

  const LoginRequested({required this.collegeId, required this.otp});

  @override
  List<Object> get props => [collegeId, otp];
}

class LogoutRequested extends AuthEvent {}

class OtpRequested extends AuthEvent {
  final String collegeId;

  const OtpRequested({required this.collegeId});

  @override
  List<Object> get props => [collegeId];
}

class RegistrationCompleted extends AuthEvent {}
