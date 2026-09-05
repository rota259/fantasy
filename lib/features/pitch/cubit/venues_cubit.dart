import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/supabase_config.dart';
import '../data/models/venue.dart';
import '../data/venues_repository.dart';

part 'venues_state.dart';

/// ViewModel لقائمة الملاعب. demo → فاضي فالشاشة تستخدم الـ mock.
class VenuesCubit extends Cubit<VenuesState> {
  VenuesCubit(this._repo) : super(const VenuesState());

  final VenuesRepository _repo;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const VenuesState(status: VenuesStatus.loaded));
      return;
    }
    emit(const VenuesState(status: VenuesStatus.loading));
    try {
      final venues = await _repo.fetchAll();
      emit(VenuesState(status: VenuesStatus.loaded, venues: venues));
    } catch (_) {
      emit(const VenuesState(status: VenuesStatus.loaded));
    }
  }
}
