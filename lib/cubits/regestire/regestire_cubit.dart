import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fantasy_5omasi/models/user_model.dart';
import 'package:fantasy_5omasi/repositories/auth_repository.dart';
import 'regestire_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository authRepository;

  RegisterCubit(this.authRepository) : super(RegisterInitial());

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    emit(RegisterLoading());
    try {
      final newUser = UserModel(
        uid: '',
        name: name,
        email: email,
        phone: phone,
        role: role, // ← استخدم القيمة اللي جاية من الفورم
        team: [],
        createdAt: DateTime.now(),
        favEuropeanTeam: null,
        favLocalTeam: null,
      );

      final registeredUser = await authRepository.register(newUser, password);
      emit(RegisterSuccess(registeredUser));
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }
}
