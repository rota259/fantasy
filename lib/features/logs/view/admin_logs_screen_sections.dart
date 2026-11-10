part of 'admin_logs_screen.dart';

extension _AdminLogsSections on _AdminLogsScreenState {
  /// لوحة الأرقام: الأخطاء · الطلبات الفاشلة · السرعة · نبض السيرفر · أكتر الأخطاء.
  Widget _statsCard(LogStats s) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    padding: const EdgeInsets.all(14),
    decoration: AppDecor.tile,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _num('${s.errors1h}', 'أخطاء · ساعة', s.errors1h > 0 ? AppColors.danger : AppColors.accent700),
            _num('${s.errors24h}', 'أخطاء · يوم', s.errors24h > 0 ? AppColors.danger : AppColors.accent700),
            _num('${s.usersHit}', 'يوزر اتأثر', AppColors.ink),
            _num('${s.p95}ms', 'سرعة p95', s.p95 > 4000 ? AppColors.danger : AppColors.ink),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              s.serverStale ? Icons.error_outline : Icons.favorite,
              size: 15,
              color: s.serverStale ? AppColors.danger : AppColors.accent700,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.serverBeat == null
                    ? 'مهام السيرفر المجدولة عمرها ما اشتغلت — فعّل pg_cron'
                    : s.serverStale
                    ? 'مهام السيرفر واقفة من ${arabicTime(s.serverBeat!)} — راجع pg_cron'
                    : 'مهام السيرفر شغّالة · آخر نبضة ${arabicTime(s.serverBeat!)}',
                style: AppText.body(11, color: s.serverStale ? AppColors.danger : AppColors.neutral700),
              ),
            ),
          ],
        ),
        if (s.topErrors.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('أكتر الأخطاء في آخر يوم', style: AppText.kicker()),
          for (final e in s.topErrors)
            Pressable(
              onTap: () => _searchFor(e.name),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.body(12)),
                    ),
                    Text('${e.count}×', style: AppText.h(12, color: AppColors.danger)),
                  ],
                ),
              ),
            ),
        ],
      ],
    ),
  );

  Widget _num(String v, String k, Color color) => Expanded(
    child: Column(
      children: [
        FittedBox(
          child: Text(v, style: AppText.h(20, color: color)),
        ),
        Text(k, style: AppText.body(10, color: AppColors.neutral700)),
      ],
    ),
  );

  void _searchFor(String q) {
    _search.text = q;
    _update(() => _level = null);
    _load();
  }

  /// البحث: رقم الطلب (req_…) · رقم اليوزر · اسم الحدث · نوع الخطأ.
  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: TextField(
      controller: _search,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _load(),
      style: AppText.body(13),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'رقم الطلب req_… · رقم اليوزر · اسم الحدث',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  _search.clear();
                  _load();
                },
              ),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: AppRadius.md, borderSide: BorderSide.none),
      ),
    ),
  );

  Widget _filterChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(
      children: [
        for (final f in _AdminLogsScreenState._filters)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(f.$2),
              selected: _level == f.$1,
              onSelected: (_) {
                _update(() => _level = f.$1);
                _load();
              },
            ),
          ),
      ],
    ),
  );
}
