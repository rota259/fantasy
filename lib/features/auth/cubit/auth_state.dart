part of 'auth_cubit.dart';

/// [verifyEmail] = الحساب محتاج كود تأكيد الإيميل ([AuthState.pendingEmail]).
enum AuthStatus { unknown, authenticating, authenticated, unauthenticated, error, verifyEmail }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.message, this.pendingEmail});

  final AuthStatus status;
  final AppUser? user;
  final String? message; // رسالة الخطأ لو فيه
  final String? pendingEmail; // الإيميل اللي مستني كود التأكيد

  bool get isBusy => status == AuthStatus.authenticating;

  @override
  List<Object?> get props => [status, user, message, pendingEmail];
}
