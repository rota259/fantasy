import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../leagues/data/leagues_repository.dart';

part 'account_state.dart';

/// ViewModel لشاشة الحساب — بيجيب الترتيب العام للمستخدم.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repo) : super(const AccountState());

  final LeaguesRepository _repo;

  Future<void> load(String? userId) async {
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const AccountState(status: AccountStatus.loaded));
      return;
    }
    emit(const AccountState(status: AccountStatus.loading));
    try {
      final rank = await _repo.globalRank(userId);
      emit(AccountState(status: AccountStatus.loaded, rank: rank));
    } catch (_) {
      emit(const AccountState(status: AccountStatus.loaded));
    }
  }
}
