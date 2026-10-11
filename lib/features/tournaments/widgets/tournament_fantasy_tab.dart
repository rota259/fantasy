import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/db_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/fx/skeleton.dart';
import '../../../core/widgets/jersey.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/net_image.dart';
import '../data/models/tournament.dart';
import '../data/tournaments_repository.dart';

/// فانتازي البطولة: تشكيلة لوحدها لكل بطولة — ٥ لاعيبة من فرقها (حارس + ٤ · ٢ بحد أقصى من الفريق) وكابتن ×٢.
/// تتغيّر بين الماتشات (مقفولة وماتش شغال)، ولها ترتيب لوحدها.
class TournamentFantasyTab extends StatefulWidget {
  const TournamentFantasyTab({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  State<TournamentFantasyTab> createState() => _TournamentFantasyTabState();
}

class _TournamentFantasyTabState extends State<TournamentFantasyTab> {
  late final TournamentsRepository _repo = context.read<TournamentsRepository>();
  TournamentFantasy? _data;
  final _sel = <String>[];
  String? _captain;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await _repo.fantasy(widget.tournamentId);
      if (!mounted) return;
      setState(() {
        _data = d;
        _failed = false;
        _sel
          ..clear()
          ..addAll(d.mine);
        _captain = d.captain;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  FantasyPlayer? _p(String id) {
    for (final p in _data!.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// اختار/شيل لاعب — بنفس شروط السيرفر.
  void _toggle(FantasyPlayer p) {
    if (!_data!.open) return;
    if (_sel.contains(p.id)) {
      setState(() {
        _sel.remove(p.id);
        if (_captain == p.id) _captain = null;
      });
      return;
    }
    final picked = [for (final id in _sel) _p(id)].whereType<FantasyPlayer>().toList();
    if (picked.length >= 5) return _snack('التشكيلة ٥ لاعيبة — شيل واحد الأول');
    if (p.gk && picked.any((x) => x.gk)) return _snack('حارس واحد بس');
    if (!p.gk && picked.where((x) => !x.gk).length >= 4) return _snack('٤ لاعيبة وحارس — لسه محتاج الحارس');
    if (picked.where((x) => x.team == p.team).length >= 2) return _snack('بحد أقصى لاعبين من نفس الفريق');
    setState(() {
      _sel.add(p.id);
      _captain ??= p.id;
    });
  }

  Future<void> _save() async {
    if (_sel.length != 5) return _snack('اختار ٥ لاعيبة (حارس + ٤)');
    if (_captain == null) return _snack('دوس على لاعب من تشكيلتك فوق عشان يبقى الكابتن');
    setState(() => _saving = true);
    try {
      await _repo.saveFantasy(widget.tournamentId, _sel, _captain!);
      await _load();
      if (mounted) _snack('تشكيلتك في البطولة اتحفظت ✓');
    } catch (e) {
      if (mounted) _snack(dbMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    if (d == null) {
      return _failed
          ? Center(
              child: TextButton(onPressed: _load, child: const Text('حصلت مشكلة — جرّب تاني')),
            )
          : const SkeletonList();
    }
    final byTeam = <String, List<FantasyPlayer>>{};
    for (final p in d.players) {
      byTeam.putIfAbsent(p.team, () => []).add(p);
    }
    final changed = !(_sel.length == d.mine.length && _sel.every(d.mine.contains) && _captain == d.captain);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _summary(d),
          _lineup(d),
          if (d.open && changed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'بيتحفظ…' : 'احفظ تشكيلتي')),
            ),
          if (d.canPlay && !d.finished) ...[
            for (final e in byTeam.entries) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.accent100, borderRadius: AppRadius.md),
                child: Text(e.key, style: AppText.h(13, color: AppColors.accent700)),
              ),
              for (final p in e.value) _playerRow(p, d.open),
            ],
            if (d.players.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'لسه مفيش لاعيبة في فرق البطولة — المنظّم بيضيفهم',
                  textAlign: TextAlign.center,
                  style: AppText.body(13, color: AppColors.neutral600),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text('ترتيب فانتازي البطولة', style: AppText.kicker(color: AppColors.accent)),
          ),
          if (d.standings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('لسه محدش عمل تشكيلة', style: AppText.body(13, color: AppColors.neutral600)),
            ),
          for (final (i, r) in d.standings.indexed)
            FadeSlideIn(
              index: i,
              child: Container(
                margin: AppDecor.tileMargin,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: r.mine
                    ? AppDecor.tile.copyWith(border: Border.all(color: AppColors.accent, width: 1.4))
                    : AppDecor.tile,
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${r.rank}', style: AppText.h(13, color: AppColors.accent)),
                    ),
                    Expanded(child: Text(r.name, style: AppText.h(13))),
                    Text('${r.points}', style: AppText.h(17)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summary(TournamentFantasy d) {
    final note = !d.canPlay
        ? 'فانتازي البطولة لأهل منطقتها بس (وحساب المدير مش بيلعب)'
        : d.finished
        ? 'البطولة خلصت — ده الترتيب النهائي'
        : d.live
        ? 'فيه ماتش شغال — التشكيلة بتتفتح تاني لما يخلص'
        : 'اختار ٥ من فرق البطولة: حارس + ٤، وبحد أقصى ٢ من نفس الفريق. تقدر تغيّرهم بين الماتشات.';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.black, borderRadius: AppRadius.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تشكيلتي في البطولة', style: AppText.h(15, color: AppColors.white)),
                const SizedBox(height: 2),
                Text(note, style: AppText.body(11, color: AppColors.white.withValues(alpha: 0.75), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              CountUp(
                value: d.myPoints,
                style: AppText.h(30, color: AppColors.white, height: 1),
              ),
              Text(
                d.myRank == null ? 'نقطة' : 'نقطة · #${d.myRank}',
                style: AppText.body(11, color: AppColors.accent400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// الخمسة المختارين — الضغط على واحد = كابتن (×٢).
  Widget _lineup(TournamentFantasy d) {
    if (!d.canPlay) return const SizedBox.shrink();
    final picked = [for (final id in _sel) _p(id)].whereType<FantasyPlayer>().toList()
      ..sort((a, b) => (a.gk ? 0 : 1).compareTo(b.gk ? 0 : 1));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppDecor.tile,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (var i = 0; i < 5; i++) i < picked.length ? _token(picked[i], d.open) : _empty()],
          ),
          if (picked.isNotEmpty && d.open)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('دوس على لاعب عشان يبقى الكابتن (×٢)', style: AppText.body(11, color: AppColors.neutral700)),
            ),
        ],
      ),
    );
  }

  Widget _empty() => SizedBox(
    width: 58,
    child: Jersey(
      label: '+',
      size: 46,
      style: JerseyStyle(
        body: [AppColors.neutral300, AppColors.neutral200],
        trim: AppColors.neutral500,
        ink: AppColors.neutral700,
        shine: 0,
      ),
    ),
  );

  Widget _token(FantasyPlayer p, bool open) {
    final cap = p.id == _captain;
    return Pressable(
      onTap: open ? () => setState(() => _captain = p.id) : null,
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Jersey(
              label: p.name.characters.take(2).toString(),
              size: 46,
              style: cap ? JerseyStyle.gold : (p.gk ? JerseyStyle.keeper : JerseyStyle.white),
              phase: (p.id.hashCode % 100) / 100,
            ),
            const SizedBox(height: 3),
            Text(
              '${cap ? '© ' : ''}${p.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.h(10, color: cap ? AppColors.gold : AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(FantasyPlayer p, bool open) {
    final on = _sel.contains(p.id);
    final url = p.imageUrl;
    return Pressable(
      behavior: HitTestBehavior.opaque,
      onTap: open ? () => _toggle(p) : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          color: on ? AppColors.accent100 : null,
          border: Border.all(color: on ? AppColors.accent : AppColors.line),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.neutral200,
              child: url == null || url.isEmpty
                  ? Text(p.name.characters.take(2).toString(), style: AppText.h(11))
                  : ClipOval(child: NetImage(url, width: 34, height: 34)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('${p.name}${p.gk ? ' 🧤' : ''}', style: AppText.h(13))),
            Text('${p.points} ن', style: AppText.body(12, color: AppColors.neutral700)),
            const SizedBox(width: 8),
            Icon(
              on ? Icons.check_circle : Icons.add_circle_outline,
              size: 20,
              color: on ? AppColors.accent : AppColors.neutral500,
            ),
          ],
        ),
      ),
    );
  }
}
