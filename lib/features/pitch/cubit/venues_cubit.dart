import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/live.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/models/venue.dart';
import '../data/venues_repository.dart';

part 'venues_state.dart';

/// ViewModel لقائمة الملاعب — بتتحدّث لوحدها لما المدير يضيف/يعدّل ملعب.
class VenuesCubit extends Cubit<VenuesState> {
  VenuesCubit(this._repo) : super(const VenuesState());

  final VenuesRepository _repo;
  StreamSubscription<void>? _sub;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) {
      emit(const VenuesState(status: VenuesStatus.loaded));
      return;
    }
    emit(const VenuesState(status: VenuesStatus.loading));
    await _fetch();
    _sub ??= liveTable('venues', _fetch);
  }

  Future<void> _fetch() async {
    try {
      final venues = await _repo.fetchAll();
      if (!isClosed) emit(VenuesState(status: VenuesStatus.loaded, venues: venues));
    } catch (_) {
      if (!isClosed && state.isLoading) emit(const VenuesState(status: VenuesStatus.loaded));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
