part of 'auth_cubit.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.message});

  final AuthStatus status;
  final AppUser? user;
  final String? message; // رسالة الخطأ لو فيه

  bool get isBusy => status == AuthStatus.authenticating;

  @override
  List<Object?> get props => [status, user, message];
}
