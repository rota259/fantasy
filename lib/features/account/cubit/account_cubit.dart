import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../claims/data/claims_repository.dart';
import '../../leagues/data/leagues_repository.dart';
import '../../players/data/models/player.dart';
import '../../squad/data/profile_repository.dart';

part 'account_state.dart';

/// ViewModel لشاشة الحساب: الترتيب العام + أحسن ماتش + اللاعب اللي أنا موثّق عليه.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._leagues, this._profiles, this._claims) : super(const AccountState());

  final LeaguesRepository _leagues;
  final ProfileRepository _profiles;
  final ClaimsRepository _claims;

  Future<void> load(String? userId) async {
    if (!SupabaseConfig.isConfigured || userId == null) {
      emit(const AccountState(status: AccountStatus.loaded));
      return;
    }
    emit(const AccountState(status: AccountStatus.loading));
    try {
      final (rank, best, linked) = await (
        _leagues.globalRank(userId),
        _profiles.bestMatch(userId),
        _claims.linkedPlayer(userId),
      ).wait;
      emit(AccountState(status: AccountStatus.loaded, rank: rank, bestMatch: best, linkedPlayer: linked));
    } catch (_) {
      emit(const AccountState(status: AccountStatus.loaded));
    }
  }
}
