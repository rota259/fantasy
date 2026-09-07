-- ═══════════════════════════════════════════════════════════════
-- مسح كل المحتوى التجريبي القديم (اللي اتزرع من schema.sql قبل كده)
-- بيمسح: لاعيبة / ماتشات / دوريات / ملاعب / أحداث / تشكيلات / اختيارات / مزادات
-- بيسيب: حسابات المستخدمين (profiles + auth.users) زي ما هي
--
-- شغّله مرة واحدة في SQL Editor لو قاعدتك فيها بيانات تجريبية قديمة.
-- بعده التطبيق هيبقى فاضي خالص — المدير هو اللي يضيف كل حاجة.
-- ═══════════════════════════════════════════════════════════════

do $$
declare t text;
begin
  foreach t in array array[
    'events', 'lineups', 'picks', 'auction_bids', 'auctions',
    'league_members', 'leagues', 'venues', 'matches', 'players'
  ] loop
    if to_regclass('public.' || t) is not null then
      execute format('truncate table public.%I cascade', t);
    end if;
  end loop;
end $$;

-- صفّر نقاط وتشكيلات المستخدمين (بعد ما اتمسحت الأحداث/الاختيارات)
update public.profiles set total_points = 0, team = '{}', captain_id = null, league_id = null;
