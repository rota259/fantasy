import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/user_model.dart';

abstract class RegisterState extends Equatable {
  const RegisterState();
  @override
  List<Object?> get props => [];
}

class RegisterInitial extends RegisterState {}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final UserModel user;
  const RegisterSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class RegisterFailure extends RegisterState {
  final String error;
  const RegisterFailure(this.error);

  @override
  List<Object?> get props => [error];
}
