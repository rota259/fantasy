import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/supabase/supabase_config.dart';
import '../data/chip_type.dart';
import '../data/chips_repository.dart';
import '../data/models/chip_status.dart';

part 'chips_state.dart';

/// ViewModel الكروت في شاشة تشكيلة الجولة.
class ChipsCubit extends Cubit<ChipsState> {
  ChipsCubit(this._repo, this.roundEnd) : super(const ChipsState());

  final ChipsRepository _repo;
  final DateTime roundEnd;

  Future<void> load() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      final chips = await _repo.status(roundEnd);
      if (!isClosed) emit(ChipsState(loaded: true, chips: chips));
    } catch (_) {
      if (!isClosed) emit(const ChipsState(loaded: true));
    }
  }

  /// بيرجّع رسالة الخطأ أو null لو اتفعّل.
  Future<String?> activate(ChipType type) async {
    emit(state.copyWith(busy: true));
    try {
      await _repo.activate(roundEnd, type);
      await load();
      return null;
    } catch (e) {
      emit(state.copyWith(busy: false));
      return dbMessage(e, fallback: 'تعذّر تفعيل الكارت');
    }
  }
}
