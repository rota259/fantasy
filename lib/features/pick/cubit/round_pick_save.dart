part of 'round_pick_cubit.dart';

extension RoundPickSave on RoundPickCubit {
  /// غلطة في القواعد (نفس save_round_picks في السيرفر) أو null.
  String? validate() {
    final starting = state.sel.entries.where((e) => e.value == 'starting').map((e) => e.key).toList();
    final gk = starting.where((id) => state.playerById(id)?.position == 'GK').length;
    if (starting.length != RoundPickState.starters) return 'لازم ٥ أساسيين بالظبط';
    if (state.benchCount != RoundPickState.benchSize) return 'لازم ٢ احتياطي';
    if (gk != 1) return 'لازم حارس واحد في الأساسيين';
    if (state.captainId == null) return 'اختار كابتن من الأساسيين';
    if (state.viceId == null) return 'اختار كابتن بديل من الأساسيين';
    return null;
  }

  /// بيحفظ بعد التحقّق؛ بيرجّع رسالة خطأ أو null لو نجح (السيرفر بيتأكد من القفل والتغييرات تاني).
  Future<String?> save() async {
    if (window.isFinal()) return 'الجولة خلصت';
    final err = validate();
    if (err != null) return err;
    final picks = [
      for (final e in state.sel.entries)
        Pick(playerId: e.key, status: e.value, isCaptain: e.key == state.captainId, isVice: e.key == state.viceId),
    ];
    try {
      await _picks.saveRound(window.cutoff, picks);
      _emit(state.copyWith(saved: true));
      return null;
    } catch (e) {
      return dbMessage(e, fallback: 'تعذّر الحفظ — اتأكد من النت وجرّب تاني');
    }
  }
}
