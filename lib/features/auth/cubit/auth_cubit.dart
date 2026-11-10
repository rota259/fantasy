import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_log.dart';
import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/auth_repository.dart';
import '../data/models/app_user.dart';

part 'auth_state.dart';
part 'auth_cubit_actions.dart';
part 'auth_cubit_actions2.dart';

/// ViewModel للمصادقة. لو Supabase مش متظبّط بيشتغل في وضع demo (بيعدّي بدون باك-إند).
class AuthCubit extends Cubit<AuthState> {
  // emit محمي (protected) — الأجزاء المنقولة لملفات تانية بتغيّر الحالة من هنا
  void _emit(AuthState s) => emit(s);

  AuthCubit(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  bool get _live => SupabaseConfig.isConfigured;

  /// شروط كلمة السر (نفسها في التسجيل وفي التغيير).
  static String? passwordProblem(String password) {
    if (password.length < 8) return 'كلمة السر ٨ حروف على الأقل';
    if (!password.contains(RegExp(r'[0-9]')) || !password.contains(RegExp(r'[A-Za-z]'))) {
      return 'كلمة السر لازم فيها حروف وأرقام';
    }
    return null;
  }

  /// شروط التسجيل قبل ما نكلّم السيرفر.
  static String? _validateSignUp(String name, String password, int? zoneId) {
    if (name.trim().length < 2 || name.trim().length > 40) return 'الاسم من ٢ لـ ٤٠ حرف';
    final weak = passwordProblem(password);
    if (weak != null) return weak;
    if (zoneId == null) return 'اختار منطقتك';
    return null;
  }
}
