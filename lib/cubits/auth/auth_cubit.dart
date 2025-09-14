import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit(this.authRepository) : super(AuthInitial());

  // تسجيل الدخول
  Future<void> signIn(String input, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signIn(input, password);

      if (user.role.isEmpty) {
        emit(AuthFailure("نوع الحساب غير محدد"));
        return;
      }

      if (!user.isActive) {
        emit(AuthFailure("الحساب غير مفعل"));
        return;
      }

      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // تسجيل جديد
  Future<void> register(UserModel user, String password) async {
    emit(AuthLoading());
    try {
      final newUser = await authRepository.register(user, password);
      emit(AuthSuccess(newUser));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // تسجيل دخول تلقائي
  Future<void> autoLogin() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.checkAutoLogin();
      if (user != null && user.isActive && user.role.isNotEmpty) {
        emit(AuthSuccess(user));
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // تسجيل خروج
  Future<void> signOut() async {
    await authRepository.signOut();
    emit(AuthInitial());
  }
}
