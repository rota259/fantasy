-- الجزء 1 من 7 — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)
 -- ═══════════════════════════════════════════════════════════════
-- الخماسي — كل الـ migrations في ملف واحد (شغّله مرة واحدة، وتقدر تعيده)
-- Supabase Dashboard → SQL Editor → New query → الصق الكل → Run
--
-- الأقسام بالترتيب (الترتيب مهم):
--    1) schema             — الجداول wالأساسية + الأعمدة الجديدة
--    2) scoring basics     — المدير + نقاط الأحداث + حدود الجولة بالوقت
--    3) lineups            — تشكيلة كل ماتش (المدير)
--    4) picks              — تشكيلة اليوزر لكل ماتش (القراءة بس — الحفظ بدالة save_picks)
--    5) week stats         — نقاط الجولة + الامتلاك + تاريخ اللاعب
--    6) notifications      — صندوق الإشعارات (للكل / ليوزر / لمتابعين ماتش)
--    7) polls              — التصويتات (هدف/تصدّي الجولة والموسم + تعادل تشكيلة الجولة)
--    8) security & admin   — حماية البروفايل + أدوار المستخدمين + الخصوصية
--    9) venues & bookings  — الملاعب (أي يوزر يضيف) + التقييمات + الحجز
--   10) seasons & chips    — الموسم ونصّه + الكروت
--   11) challenge          — تحدّي الجولة: توقّع النتيجة (+٥)
--   12) follows            — متابعة ماتش لايف (٣ في اليوم) + إشعار كل حدث
--   13) ratings            — تقييم الجمهور + رجل المباراة (+٣)
--   14) player claims      — اللاعب الحقيقي يوثّق بروفايله
--   15) scoring v2         — حساب النقاط (الكروت + البونص) + حفظ التشكيلة الآمن
--   16) leagues            — أي يوزر يعمل دوري + المدير يدير
--   17) awards & totw      — تصويتات الموسم + تعادل تشكيلة الجولة + قفل التصويتات
--   18) badges             — الشارات والإنجازات
--   19) tick               — مهمة كل ١٠ دقايق (pg_cron)
--   20) push               — أي إشعار بيتسجّل → push أوتوماتيك (pg_net → Edge Function push)
--
-- ⚠️ كل UPDATE/DELETE لازم يبقى ليه WHERE (Supabase مشغّل pg-safeupdate).
-- الأوقات: الجولة بتوقيت القاهرة (Africa/Cairo).
-- ═══════════════════════════════════════════════════════════════


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 1) SCHEMA                                                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- المناطق: المحافظة + المنطقة. اليوزر والمنظّم والفرق والماتشات كلهم ليهم منطقة.
create table if not exists public.zones (
  id          serial primary key,
  governorate text not null,
  name        text not null,
  sort        int not null default 0,
  unique (governorate, name)
);
alter table public.zones enable row level security;
drop policy if exists "zones read" on public.zones;
create policy "zones read" on public.zones for select to anon, authenticated using (true);
insert into public.zones (governorate, name, sort) values
  ('القاهرة', 'مدينة نصر', 0),
  ('القاهرة', 'مصر الجديدة', 1),
  ('القاهرة', 'النزهة', 2),
  ('القاهرة', 'شيراتون', 3),
  ('القاهرة', 'ألماظة', 4),
  ('القاهرة', 'جسر السويس', 5),
  ('القاهرة', 'ألف مسكن', 6),
  ('القاهرة', 'الحي العاشر', 7),
  ('القاهرة', 'الحي السابع', 8),
  ('القاهرة', 'العباسية', 9),
  ('القاهرة', 'الزيتون', 10),
  ('القاهرة', 'حلمية الزيتون', 11),
  ('القاهرة', 'حدائق القبة', 12),
  ('القاهرة', 'القبة', 13),
  ('القاهرة', 'الوايلي', 14),
  ('القاهرة', 'الظاهر', 15),
  ('القاهرة', 'السكاكيني', 16),
  ('القاهرة', 'غمرة', 17),
  ('القاهرة', 'شبرا', 18),
  ('القاهرة', 'روض الفرج', 19),
  ('القاهرة', 'الساحل', 20),
  ('القاهرة', 'الشرابية', 21),
  ('القاهرة', 'الزاوية الحمراء', 22),
  ('القاهرة', 'الأميرية', 23),
  ('القاهرة', 'المطرية', 24),
  ('القاهرة', 'عين شمس', 25),
  ('القاهرة', 'المرج', 26),
  ('القاهرة', 'عزبة النخل', 27),
  ('القاهرة', 'السلام', 28),
  ('القاهرة', 'النهضة', 29),
  ('القاهرة', 'الشروق', 30),
  ('القاهرة', 'بدر', 31),
  ('القاهرة', 'مدينتي', 32),
  ('القاهرة', 'الرحاب', 33),
  ('القاهرة', 'التجمع الخامس', 34),
  ('القاهرة', 'التجمع الأول', 35),
  ('القاهرة', 'التجمع الثالث', 36),
  ('القاهرة', 'القاهرة الجديدة', 37),
  ('القاهرة', 'القطامية', 38),
  ('القاهرة', 'العاصمة الإدارية', 39),
  ('القاهرة', 'مستقبل سيتي', 40),
  ('القاهرة', 'هليوبوليس الجديدة', 41),
  ('القاهرة', 'وسط البلد', 42),
  ('القاهرة', 'عابدين', 43),
  ('القاهرة', 'الموسكي', 44),
  ('القاهرة', 'باب الشعرية', 45),
  ('القاهرة', 'الأزبكية', 46),
  ('القاهرة', 'بولاق أبو العلا', 47),
  ('القاهرة', 'الزمالك', 48),
  ('القاهرة', 'جاردن سيتي', 49),
  ('القاهرة', 'المنيل', 50),
  ('القاهرة', 'مصر القديمة', 51),
  ('القاهرة', 'السيدة زينب', 52),
  ('القاهرة', 'الخليفة', 53),
  ('القاهرة', 'المقطم', 54),
  ('القاهرة', 'منشأة ناصر', 55),
  ('القاهرة', 'الدرب الأحمر', 56),
  ('القاهرة', 'الجمالية', 57),
  ('القاهرة', 'البساتين', 58),
  ('القاهرة', 'دار السلام', 59),
  ('القاهرة', 'المعادي', 60),
  ('القاهرة', 'المعادي الجديدة', 61),
  ('القاهرة', 'زهراء المعادي', 62),
  ('القاهرة', 'دجلة', 63),
  ('القاهرة', 'طرة', 64),
  ('القاهرة', 'المعصرة', 65),
  ('القاهرة', 'حلوان', 66),
  ('القاهرة', 'حدائق حلوان', 67),
  ('القاهرة', 'عين حلوان', 68),
  ('القاهرة', '15 مايو', 69),
  ('القاهرة', 'التبين', 70),
  ('القاهرة', 'الخلفاوي', 71),
  ('الجيزة', 'الدقي', 1000),
  ('الجيزة', 'المهندسين', 1001),
  ('الجيزة', 'العجوزة', 1002),
  ('الجيزة', 'الجيزة', 1003),
  ('الجيزة', 'الهرم', 1004),
  ('الجيزة', 'فيصل', 1005),
  ('الجيزة', 'العمرانية', 1006),
  ('الجيزة', 'الطالبية', 1007),
  ('الجيزة', 'بولاق الدكرور', 1008),
  ('الجيزة', 'إمبابة', 1009),
  ('الجيزة', 'الوراق', 1010),
  ('الجيزة', 'الكيت كات', 1011),
  ('الجيزة', 'أرض اللواء', 1012),
  ('الجيزة', 'بين السرايات', 1013),
  ('الجيزة', 'المنيب', 1014),
  ('الجيزة', 'ساقية مكي', 1015),
  ('الجيزة', 'المريوطية', 1016),
  ('الجيزة', 'حدائق الأهرام', 1017),
  ('الجيزة', '6 أكتوبر', 1018),
  ('الجيزة', 'الشيخ زايد', 1019),
  ('الجيزة', 'حدائق أكتوبر', 1020),
  ('الجيزة', 'الحوامدية', 1021),
  ('الجيزة', 'البدرشين', 1022),
  ('الجيزة', 'العياط', 1023),
  ('الجيزة', 'الصف', 1024),
  ('الجيزة', 'أطفيح', 1025),
  ('الجيزة', 'كرداسة', 1026),
  ('الجيزة', 'أبو النمرس', 1027),
  ('الجيزة', 'أوسيم', 1028),
  ('القليوبية', 'شبرا الخيمة', 2000),
  ('القليوبية', 'بهتيم', 2001),
  ('القليوبية', 'مسطرد', 2002),
  ('القليوبية', 'الخصوص', 2003),
  ('القليوبية', 'العبور', 2004),
  ('القليوبية', 'الخانكة', 2005),
  ('القليوبية', 'قليوب', 2006),
  ('القليوبية', 'القناطر الخيرية', 2007),
  ('القليوبية', 'بنها', 2008),
  ('القليوبية', 'طوخ', 2009),
  ('القليوبية', 'قها', 2010),
  ('القليوبية', 'كفر شكر', 2011),
  ('القليوبية', 'شبين القناطر', 2012),
  ('الإسكندرية', 'المنتزه', 3000),
  ('الإسكندرية', 'أبو قير', 3001),
  ('الإسكندرية', 'المعمورة', 3002),
  ('الإسكندرية', 'سيدي بشر', 3003),
  ('الإسكندرية', 'ميامي', 3004),
  ('الإسكندرية', 'العصافرة', 3005),
  ('الإسكندرية', 'المندرة', 3006),
  ('الإسكندرية', 'سموحة', 3007),
  ('الإسكندرية', 'سيدي جابر', 3008),
  ('الإسكندرية', 'كليوباترا', 3009),
  ('الإسكندرية', 'رشدي', 3010),
  ('الإسكندرية', 'ستانلي', 3011),
  ('الإسكندرية', 'لوران', 3012),
  ('الإسكندرية', 'جليم', 3013),
  ('الإسكندرية', 'محرم بك', 3014),
  ('الإسكندرية', 'الإبراهيمية', 3015),
  ('الإسكندرية', 'كامب شيزار', 3016),
  ('الإسكندرية', 'الشاطبي', 3017),
  ('الإسكندرية', 'العطارين', 3018),
  ('الإسكندرية', 'المنشية', 3019),
  ('الإسكندرية', 'الجمرك', 3020),
  ('الإسكندرية', 'الأنفوشي', 3021),
  ('الإسكندرية', 'اللبان', 3022),
  ('الإسكندرية', 'كرموز', 3023),
  ('الإسكندرية', 'مينا البصل', 3024),
  ('الإسكندرية', 'القباري', 3025),
  ('الإسكندرية', 'الورديان', 3026),
  ('الإسكندرية', 'العجمي', 3027),
  ('الإسكندرية', 'الهانوفيل', 3028),
  ('الإسكندرية', 'البيطاش', 3029),
  ('الإسكندرية', 'الدخيلة', 3030),
  ('الإسكندرية', 'العامرية', 3031),
  ('الإسكندرية', 'برج العرب', 3032),
  ('الإسكندرية', 'برج العرب الجديدة', 3033),
  ('الدقهلية', 'المنصورة', 4000),
  ('الدقهلية', 'المنصورة الجديدة', 4001),
  ('الدقهلية', 'طلخا', 4002),
  ('الدقهلية', 'ميت غمر', 4003),
  ('الدقهلية', 'السنبلاوين', 4004),
  ('الدقهلية', 'أجا', 4005),
  ('الدقهلية', 'دكرنس', 4006),
  ('الدقهلية', 'بلقاس', 4007),
  ('الدقهلية', 'شربين', 4008),
  ('الدقهلية', 'المنزلة', 4009),
  ('الدقهلية', 'جمصة', 4010),
  ('الدقهلية', 'نبروه', 4011),
  ('الدقهلية', 'منية النصر', 4012),
  ('الدقهلية', 'تمي الأمديد', 4013),
  ('الدقهلية', 'بني عبيد', 4014),
  ('الدقهلية', 'الجمالية', 4015),
  ('الشرقية', 'الزقازيق', 5000),
  ('الشرقية', 'العاشر من رمضان', 5001),
  ('الشرقية', 'بلبيس', 5002),
  ('الشرقية', 'منيا القمح', 5003),
  ('الشرقية', 'أبو حماد', 5004),
  ('الشرقية', 'فاقوس', 5005),
  ('الشرقية', 'ههيا', 5006),
  ('الشرقية', 'الحسينية', 5007),
  ('الشرقية', 'أبو كبير', 5008),
  ('الشرقية', 'ديرب نجم', 5009),
  ('الشرقية', 'كفر صقر', 5010),
  ('الشرقية', 'أولاد صقر', 5011),
  ('الشرقية', 'مشتول السوق', 5012),
  ('الشرقية', 'القنايات', 5013),
  ('الشرقية', 'الإبراهيمية', 5014),
  ('الشرقية', 'الصالحية الجديدة', 5015),
  ('الغربية', 'طنطا', 6000),
  ('الغربية', 'المحلة الكبرى', 6001),
  ('الغربية', 'كفر الزيات', 6002),
  ('الغربية', 'زفتى', 6003),
  ('الغربية', 'السنطة', 6004),
  ('الغربية', 'سمنود', 6005),
  ('الغربية', 'بسيون', 6006),
  ('الغربية', 'قطور', 6007),
  ('المنوفية', 'شبين الكوم', 7000),
  ('المنوفية', 'مدينة السادات', 7001),
  ('المنوفية', 'منوف', 7002),
  ('المنوفية', 'أشمون', 7003),
  ('المنوفية', 'الباجور', 7004),
  ('المنوفية', 'قويسنا', 7005),
  ('المنوفية', 'بركة السبع', 7006),
  ('المنوفية', 'تلا', 7007),
  ('المنوفية', 'الشهداء', 7008),
  ('المنوفية', 'سرس الليان', 7009),
  ('البحيرة', 'دمنهور', 8000),
  ('البحيرة', 'كفر الدوار', 8001),
  ('البحيرة', 'رشيد', 8002),
  ('البحيرة', 'إدكو', 8003),
  ('البحيرة', 'أبو المطامير', 8004),
  ('البحيرة', 'حوش عيسى', 8005),
  ('البحيرة', 'إيتاي البارود', 8006),
  ('البحيرة', 'شبراخيت', 8007),
  ('البحيرة', 'المحمودية', 8008),
  ('البحيرة', 'الرحمانية', 8009),
  ('البحيرة', 'كوم حمادة', 8010),
  ('البحيرة', 'الدلنجات', 8011),
  ('البحيرة', 'وادي النطرون', 8012),
  ('البحيرة', 'أبو حمص', 8013),
  ('كفر الشيخ', 'كفر الشيخ', 9000),
  ('كفر الشيخ', 'دسوق', 9001),
  ('كفر الشيخ', 'فوه', 9002),
  ('كفر الشيخ', 'بلطيم', 9003),
  ('كفر الشيخ', 'سيدي سالم', 9004),
  ('كفر الشيخ', 'قلين', 9005),
  ('كفر الشيخ', 'الرياض', 9006),
  ('كفر الشيخ', 'بيلا', 9007),
  ('كفر الشيخ', 'الحامول', 9008),
  ('كفر الشيخ', 'مطوبس', 9009),
  ('دمياط', 'دمياط', 10000),
  ('دمياط', 'دمياط الجديدة', 10001),
  ('دمياط', 'رأس البر', 10002),
  ('دمياط', 'فارسكور', 10003),
  ('دمياط', 'الزرقا', 10004),
  ('دمياط', 'كفر سعد', 10005),
  ('دمياط', 'كفر البطيخ', 10006),
  ('دمياط', 'عزبة البرج', 10007),
  ('بورسعيد', 'حي الشرق', 11000),
  ('بورسعيد', 'حي العرب', 11001),
  ('بورسعيد', 'حي المناخ', 11002),
  ('بورسعيد', 'حي الضواحي', 11003),
  ('بورسعيد', 'حي الزهور', 11004),
  ('بورسعيد', 'حي الجنوب', 11005),
  ('بورسعيد', 'بورفؤاد', 11006),
  ('الإسماعيلية', 'الإسماعيلية', 12000),
  ('الإسماعيلية', 'فايد', 12001),
  ('الإسماعيلية', 'القنطرة شرق', 12002),
  ('الإسماعيلية', 'القنطرة غرب', 12003),
  ('الإسماعيلية', 'التل الكبير', 12004),
  ('الإسماعيلية', 'أبو صوير', 12005),
  ('الإسماعيلية', 'القصاصين', 12006),
  ('السويس', 'حي السويس', 13000),
  ('السويس', 'الأربعين', 13001),
  ('السويس', 'الجناين', 13002),
  ('السويس', 'عتاقة', 13003),
  ('السويس', 'فيصل', 13004),
  ('الفيوم', 'الفيوم', 14000),
  ('الفيوم', 'الفيوم الجديدة', 14001),
  ('الفيوم', 'سنورس', 14002),
  ('الفيوم', 'إطسا', 14003),
  ('الفيوم', 'طامية', 14004),
  ('الفيوم', 'يوسف الصديق', 14005),
  ('الفيوم', 'إبشواي', 14006),
  ('بني سويف', 'بني سويف', 15000),
  ('بني سويف', 'بني سويف الجديدة', 15001),
  ('بني سويف', 'الواسطى', 15002),
  ('بني سويف', 'ناصر', 15003),
  ('بني سويف', 'إهناسيا', 15004),
  ('بني سويف', 'ببا', 15005),
  ('بني سويف', 'الفشن', 15006),
  ('بني سويف', 'سمسطا', 15007),
  ('المنيا', 'المنيا', 16000),
  ('المنيا', 'المنيا الجديدة', 16001),
  ('المنيا', 'ملوي', 16002),
  ('المنيا', 'سمالوط', 16003),
  ('المنيا', 'مطاي', 16004),
  ('المنيا', 'بني مزار', 16005),
  ('المنيا', 'مغاغة', 16006),
  ('المنيا', 'العدوة', 16007),
  ('المنيا', 'أبو قرقاص', 16008),
  ('المنيا', 'دير مواس', 16009),
  ('أسيوط', 'أسيوط', 17000),
  ('أسيوط', 'أسيوط الجديدة', 17001),
  ('أسيوط', 'ديروط', 17002),
  ('أسيوط', 'القوصية', 17003),
  ('أسيوط', 'منفلوط', 17004),
  ('أسيوط', 'أبنوب', 17005),
  ('أسيوط', 'أبو تيج', 17006),
  ('أسيوط', 'الغنايم', 17007),
  ('أسيوط', 'ساحل سليم', 17008),
  ('أسيوط', 'البداري', 17009),
  ('أسيوط', 'صدفا', 17010),
  ('سوهاج', 'سوهاج', 18000),
  ('سوهاج', 'سوهاج الجديدة', 18001),
  ('سوهاج', 'أخميم', 18002),
  ('سوهاج', 'طهطا', 18003),
  ('سوهاج', 'جرجا', 18004),
  ('سوهاج', 'البلينا', 18005),
  ('سوهاج', 'المراغة', 18006),
  ('سوهاج', 'طما', 18007),
  ('سوهاج', 'جهينة', 18008),
  ('سوهاج', 'دار السلام', 18009),
  ('سوهاج', 'المنشأة', 18010),
  ('سوهاج', 'ساقلتة', 18011),
  ('قنا', 'قنا', 19000),
  ('قنا', 'قنا الجديدة', 19001),
  ('قنا', 'نجع حمادي', 19002),
  ('قنا', 'دشنا', 19003),
  ('قنا', 'قوص', 19004),
  ('قنا', 'أبو تشت', 19005),
  ('قنا', 'فرشوط', 19006),
  ('قنا', 'الوقف', 19007),
  ('قنا', 'نقادة', 19008),
  ('قنا', 'قفط', 19009),
  ('الأقصر', 'الأقصر', 20000),
  ('الأقصر', 'طيبة الجديدة', 20001),
  ('الأقصر', 'إسنا', 20002),
  ('الأقصر', 'أرمنت', 20003),
  ('الأقصر', 'البياضية', 20004),
  ('الأقصر', 'الطود', 20005),
  ('الأقصر', 'القرنة', 20006),
  ('أسوان', 'أسوان', 21000),
  ('أسوان', 'أسوان الجديدة', 21001),
  ('أسوان', 'كوم أمبو', 21002),
  ('أسوان', 'إدفو', 21003),
  ('أسوان', 'دراو', 21004),
  ('أسوان', 'نصر النوبة', 21005),
  ('أسوان', 'أبو سمبل', 21006),
  ('البحر الأحمر', 'الغردقة', 22000),
  ('البحر الأحمر', 'سفاجا', 22001),
  ('البحر الأحمر', 'القصير', 22002),
  ('البحر الأحمر', 'مرسى علم', 22003),
  ('البحر الأحمر', 'رأس غارب', 22004),
  ('البحر الأحمر', 'الشلاتين', 22005),
  ('مطروح', 'مرسى مطروح', 23000),
  ('مطروح', 'العلمين', 23001),
  ('مطروح', 'العلمين الجديدة', 23002),
  ('مطروح', 'الضبعة', 23003),
  ('مطروح', 'الحمام', 23004),
  ('مطروح', 'سيوة', 23005),
  ('مطروح', 'السلوم', 23006),
  ('شمال سيناء', 'العريش', 24000),
  ('شمال سيناء', 'بئر العبد', 24001),
  ('شمال سيناء', 'الشيخ زويد', 24002),
  ('شمال سيناء', 'رفح', 24003),
  ('جنوب سيناء', 'شرم الشيخ', 25000),
  ('جنوب سيناء', 'الطور', 25001),
  ('جنوب سيناء', 'دهب', 25002),
  ('جنوب سيناء', 'نويبع', 25003),
  ('جنوب سيناء', 'سانت كاترين', 25004),
  ('جنوب سيناء', 'رأس سدر', 25005),
  ('الوادي الجديد', 'الخارجة', 26000),
  ('الوادي الجديد', 'الداخلة', 26001),
  ('الوادي الجديد', 'الفرافرة', 26002),
  ('الوادي الجديد', 'باريس', 26003),
  ('الوادي الجديد', 'بلاط', 26004)
on conflict (governorate, name) do update set sort = excluded.sort;

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null default '',
  email       text not null default '',
  phone       text,
  role        text not null default 'user',        -- 'user' | 'manager'
  team        text[] not null default '{}',
  league_id   uuid,
  photo_url   text,                                 -- صورة البروفايل
  position    text,
  captain_id  uuid,
  total_points int not null default 0,              -- بيتحسب في السيرفر بس
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);
alter table public.profiles add column if not exists fcm_token    text;
alter table public.profiles add column if not exists referred_by  uuid references public.profiles(id) on delete set null;
alter table public.profiles add column if not exists badges_dirty boolean not null default false;
-- كسر التعادل في الترتيب (بيتحسب في السيرفر لما كل ماتش يبدأ): لاعيبة امتلاكها < ٢٥٪ + متوسط امتلاك اختياراته
alter table public.profiles add column if not exists low_picks int not null default 0;
alter table public.profiles add column if not exists avg_own numeric not null default 100;
create index if not exists profiles_rank on public.profiles (total_points desc, low_picks desc, avg_own);
-- منطقة اليوزر (بتتغيّر بـ set_my_zone بس — مرة كل ٣٠ يوم)
alter table public.profiles add column if not exists zone_id int references public.zones(id);
alter table public.profiles add column if not exists zone_changed_at timestamptz;
create index if not exists profiles_zone on public.profiles(zone_id);
-- كود الدعوة بتاع اليوزر (٦ حروف) — اللي يسجّل بيه يتحسب في شارة "المؤثر"
alter table public.profiles add column if not exists ref_code text
  default upper(substr(md5(gen_random_uuid()::text), 1, 6));
update public.profiles set ref_code = upper(substr(md5(gen_random_uuid()::text), 1, 6)) where ref_code is null;
create unique index if not exists profiles_ref_code on public.profiles(ref_code);

create table if not exists public.players (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  team          text not null default '',
  position      text not null default '',           -- GK | DEF | MID | FWD
  price         numeric not null default 0,
  image_url     text,
  total_points  int not null default 0,
  form          numeric not null default 0,
  goals         int not null default 0,
  assists       int not null default 0,
  clean_sheets  int not null default 0,
  yellow_cards  int not null default 0,
  availability  text not null default 'ready',       -- ready | injured | doubtful | suspended
  news          text
);
alter table public.players add column if not exists availability text not null default 'ready';
alter table public.players add column if not exists news text;
-- اللاعب الحقيقي اللي وثّق البروفايل ده (يوزر واحد لكل لاعب)
alter table public.players add column if not exists user_id uuid references public.profiles(id) on delete set null;
create unique index if not exists players_user_unique on public.players(user_id) where user_id is not null;
alter table public.players add column if not exists created_by uuid references public.profiles(id) on delete set null;
alter table public.players add column if not exists zone_id int references public.zones(id);   -- من فريقه (trigger)
create index if not exists players_zone on public.players(zone_id);

create table if not exists public.matches (
  id         uuid primary key default gen_random_uuid(),
  date_time  timestamptz not null,
  teams      text[] not null default '{}',
  status     text not null default 'upcoming',      -- upcoming | finished
  week       int not null default 0,
  fdr        int not null default 3
);
alter table public.matches add column if not exists score_a int;
alter table public.matches add column if not exists score_b int;
alter table public.matches add column if not exists finished_at timestamptz;          -- وقت ما المدير قفله
alter table public.matches add column if not exists is_challenge boolean not null default false; -- تحدّي الجولة
alter table public.matches add column if not exists motm_player_id uuid references public.players(id) on delete set null;
alter table public.matches add column if not exists motm_done boolean not null default false;
alter table public.matches add column if not exists captains_notified boolean not null default false;
alter table public.matches add column if not exists tiebreak_done boolean not null default false;
create index if not exists matches_status_date on public.matches(status, date_time);
-- نزاهة الماتشات: المنظّم + حالة الاعتماد (open → pending → approved | disputed | void)
alter table public.matches add column if not exists organizer_id uuid references public.profiles(id) on delete set null;
alter table public.matches add column if not exists review_status text not null default 'open';
alter table public.matches add column if not exists review_due timestamptz;      -- بيتعتمد لوحده بعدها (لو مفيش علامات)
alter table public.matches add column if not exists flags text[] not null default '{}';  -- علامات الغرابة
do $$ begin
  alter table public.matches add constraint matches_review_status
    check (review_status in ('open', 'pending', 'approved', 'disputed', 'void'));
exception when duplicate_object then null; end $$;
create index if not exists matches_review on public.matches(review_status, review_due);
create index if not exists matches_organizer on public.matches(organizer_id);
alter table public.matches add column if not exists zone_id int references public.zones(id);   -- من فريقه الأول
create index if not exists matches_zone on public.matches(zone_id, status, date_time);
-- الماتشات القديمة اللي خلصت قبل النظام ده = معتمدة
update public.matches set review_status = 'approved' where status = 'finished' and review_status = 'open';
create index if not exists matches_date on public.matches(date_time);

-- الفرق: كل فريق ليه اسم (مميّز في الأبلكيشن كله) + منطقة + صاحب (المنظّم).
-- اسم الفريق هو اللي في players.team و matches.teams — فمحدش يقدر يستخدم لاعيبة فريق مش بتاعه.
create table if not exists public.teams (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (length(trim(name)) between 1 and 40),
  zone_id    int references public.zones(id),
  owner_id   uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create unique index if not exists teams_name_unique on public.teams (lower(trim(name)));
create index if not exists teams_owner on public.teams(owner_id);
create index if not exists teams_zone on public.teams(zone_id);
-- الفرق القديمة (من غير صاحب ولا منطقة — الأدمن يحدد منطقتها)
insert into public.teams (name)
select distinct on (lower(trim(x.t))) trim(x.t)
from (select team as t from public.players union select unnest(teams) from public.matches) x
where trim(x.t) <> ''
  and not exists (select 1 from public.teams tm where lower(trim(tm.name)) = lower(trim(x.t)));

create table if not exists public.leagues (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  type         text not null default 'public',      -- public | private | h2h
  invite_code  text unique
);
alter table public.leagues add column if not exists owner_id uuid references public.profiles(id) on delete set null;
alter table public.leagues add column if not exists created_at timestamptz not null default now();

create table if not exists public.league_members (
  league_id  uuid references public.leagues(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  joined_at  timestamptz not null default now(),
  primary key (league_id, user_id)
);

create table if not exists public.venues (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  price        int not null default 0,
  distance_km  numeric not null default 0,
  surface      text not null default 'نجيلة صناعية',
  feature      text,
  capacity     int not null default 10,
  filled       int not null default 0,
  slot_time    text default ''
);

-- (المزاد اتشال من التطبيق — الجداول القديمة سايبينها زي ما هي من غير استخدام)
create table if not exists public.auctions (
  id                uuid primary key default gen_random_uuid(),
  name              text not null,
  current_player_id uuid references public.players(id) on delete set null,
  base_price        numeric not null default 6,
  ends_at           timestamptz,
  status            text not null default 'live'
);
create table if not exists public.auction_bids (
  id          uuid primary key default gen_random_uuid(),
  auction_id  uuid references public.auctions(id) on delete cascade,
  user_id     uuid references public.profiles(id) on delete cascade,
  bidder_name text not null default '',
  amount      numeric not null,
  created_at  timestamptz not null default now()
);
alter table public.auctions drop constraint if exists auctions_current_player_id_fkey;
alter table public.auctions add constraint auctions_current_player_id_fkey
  foreign key (current_player_id) references public.players(id) on delete set null;

create table if not exists public.events (
  id         uuid primary key default gen_random_uuid(),
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  type       text not null,
  minute     int
);
create index if not exists events_match on public.events(match_id);
alter table public.events add column if not exists other_player_id uuid references public.players(id) on delete set null; -- التبديل: اللي طلع
create index if not exists events_player on public.events(player_id);

-- الدخول برقم الموبايل: يحوّل الرقم لإيميل (للسيرفر بس — الأبلكيشن بيدخل بالرقم من auth-phone)
create or replace function public.email_for_phone(p text)
returns text language sql security definer set search_path = public as $$
  select email from public.profiles where phone = p limit 1;
$$;
grant execute on function public.email_for_phone(text) to service_role;   -- للسيرفر بس (قسم 44)

alter table public.profiles       enable row level security;
alter table public.players        enable row level security;
alter table public.matches        enable row level security;
alter table public.leagues        enable row level security;
alter table public.league_members enable row level security;
alter table public.venues         enable row level security;
alter table public.auctions       enable row level security;
alter table public.auction_bids   enable row level security;
alter table public.events         enable row level security;

drop policy if exists "profiles read"   on public.profiles;
drop policy if exists "profiles insert" on public.profiles;
drop policy if exists "profiles update" on public.profiles;
create policy "profiles read"   on public.profiles for select to authenticated using (true);
create policy "profiles insert" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles update" on public.profiles for update to authenticated using (auth.uid() = id);

drop policy if exists "players read" on public.players;
drop policy if exists "matches read" on public.matches;
drop policy if exists "events read"  on public.events;
drop policy if exists "venues read"  on public.venues;
create policy "players read" on public.players for select to authenticated using (true);
create policy "matches read" on public.matches for select to authenticated using (true);
create policy "events read"  on public.events  for select to authenticated using (true);
create policy "venues read"  on public.venues  for select to authenticated using (true);

drop policy if exists "auctions read" on public.auctions;
drop policy if exists "bids read"     on public.auction_bids;
drop policy if exists "bids insert"   on public.auction_bids;

-- حساب مدير المنطقة (organizer) = حساب شغل: مش بيلعب فانتازي ولا بيصوّت ولا بيظهر في الترتيب
create or replace function public.fn_is_zone_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'organizer');
$$;

drop policy if exists "members read"   on public.league_members;
drop policy if exists "members insert" on public.league_members;
drop policy if exists "members delete" on public.league_members;
create policy "members read"   on public.league_members for select to authenticated using (true);
-- الانضمام المباشر: الدوريات العامة أو دوريك انت بس (الخاص بالكود من join_league)
create policy "members insert" on public.league_members for insert to authenticated
  with check (auth.uid() = user_id and not public.fn_is_zone_manager()
              and exists (select 1 from public.leagues l
                          where l.id = league_members.league_id and (l.type = 'public' or l.owner_id = auth.uid())));


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 2) SCORING BASICS                                              ║
-- ╚═══════════════════════════════════════════════════════════════╝

create or replace function public.is_manager()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'manager');
$$;

-- الأدوار: user · organizer (منظّم ماتشات بموافقة الأدمن) · manager (الأدمن)
create or replace function public.is_organizer()
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role in ('organizer', 'manager'));
$$;

-- المنظّم بيدير ماتشاته بس، ولحد ما تتعتمد (بعدها أي تعديل من الأدمن)
create or replace function public.fn_organizes(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.matches m join public.profiles p on p.id = auth.uid()
                where m.id = p_match and m.organizer_id = auth.uid() and p.role = 'organizer'
                  and m.review_status in ('open', 'pending'));
$$;

-- حدث في ماتش: اللاعب لازم يكون في تشكيلة الماتش، والماتش بدأ (أو فاضله ربع ساعة)
create or replace function public.fn_event_ok(p_match uuid, p_player uuid)
returns boolean language plpgsql stable security definer set search_path = public as $$
begin
  return exists(select 1 from public.lineups l where l.match_id = p_match and l.player_id = p_player)
     and exists(select 1 from public.matches m where m.id = p_match
                and (m.date_time - interval '15 minutes' <= now() or public.fn_test_mode()))
     -- بحد ١٥٠ حدث للماتش (هنا مش في السياسة عشان السياسة متسألش جدول الأحداث نفسه)
     and (select count(*) from public.events e where e.match_id = p_match) < 150;
end $$;

drop policy if exists "players manager write" on public.players;
create policy "players manager write" on public.players for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
-- المنظّم يضيف لاعيبة ويعدّل اللي هو ضافهم (الإحصائيات والتوثيق محميين بـ trigger)
drop policy if exists "players organizer insert" on public.players;
create policy "players organizer insert" on public.players for insert to authenticated
  with check (public.is_organizer()
              and (select count(*) from public.players p where p.created_by = auth.uid()) < 300);
drop policy if exists "players organizer update" on public.players;
create policy "players organizer update" on public.players for update to authenticated
  using (created_by = auth.uid() and public.is_organizer()) with check (created_by = auth.uid());

drop policy if exists "matches manager write" on public.matches;
create policy "matches manager write" on public.matches for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
drop policy if exists "matches organizer insert" on public.matches;
create policy "matches organizer insert" on public.matches for insert to authenticated
  with check (public.is_organizer()
              and (select count(*) from public.matches m
                   where m.organizer_id = auth.uid() and m.status = 'upcoming') < 60);
drop policy if exists "matches organizer update" on public.matches;
create policy "matches organizer update" on public.matches for update to authenticated
  using (public.fn_organizes(id)) with check (organizer_id = auth.uid());
drop policy if exists "matches organizer delete" on public.matches;
create policy "matches organizer delete" on public.matches for delete to authenticated
  using (public.fn_organizes(id) and date_time > now());

drop policy if exists "events manager write" on public.events;
create policy "events manager write" on public.events for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
drop policy if exists "events organizer write" on public.events;
create policy "events organizer write" on public.events for all to authenticated
  using (public.fn_organizes(match_id))
  with check (public.fn_organizes(match_id) and public.fn_event_ok(match_id, player_id));

-- ═══ نظام النقط ═══ (بيتحسب لكل لاعب في كل ماتش — القواعد كلها هنا بس)
--   هدف +٥ (الحارس +٨) · أسيست +٣
--   هاتريك أهداف: بونص +٦، وأي هدف بعد التالت +٧ بدل ٥ · هاتريك أسيست: بونص +٤، وأي أسيست بعد التالت +٥ بدل ٣
--   مشاركة: +٣ لكل لاعب أساسي في تشكيلة الماتش (بتتضاف أول ما التشكيلة تنزل)
--   كل ٣ تصديات = +١ · صد بلنتي +٤ · كلين شيت (استقبل ٤ أو أقل) +٨ للحارس الأساسي — أوتوماتيك من النتيجة
--   كل ٥ تدخلات دفاعية = +١ · ضيّع بلنتي −٣ · سب الدين −٥ · جول عكسي −٢ · رجل المباراة (تصويت الجمهور) +٣
--   كارت أصفر −١ · كارت أحمر −٢ · التبديل مالوش نقط
drop function if exists public.fn_score_points(text, int, int, int, int, int, int, int, int, int, boolean);
drop function if exists public.fn_score_points(text, int, int, int, int, int, int, int, int, int, boolean, int, int);
create or replace function public.fn_score_points(p_pos text, g int, a int, sv int, ps int, pm int,
                                                  tk int, ins int, og int, motm int, cs boolean,
                                                  yc int default 0, rc int default 0, st boolean default false)
returns int language sql immutable as $$
  select (case when p_pos = 'GK' then g * 8 else least(g, 3) * 5 + greatest(g - 3, 0) * 7 end)
       + case when g >= 3 then 6 else 0 end
       + least(a, 3) * 3 + greatest(a - 3, 0) * 5 + case when a >= 3 then 4 else 0 end
       + sv / 3 + ps * 4 + case when cs then 8 else 0 end + case when st then 3 else 0 end
       + tk / 5 - pm * 3 - ins * 5 - og * 2 + motm * 3 - yc - rc * 2;
$$;

-- تفصيل نقط لاعب في ماتش (للشاشة): [{k: الاسم, n: العدد, p: النقط}]
drop function if exists public.fn_score_items(text, int, int, int, int, int, int, int, int, int, boolean);
drop function if exists public.fn_score_items(text, int, int, int, int, int, int, int, int, int, boolean, int, int);
create or replace function public.fn_score_items(p_pos text, g int, a int, sv int, ps int, pm int,
                                                 tk int, ins int, og int, motm int, cs boolean,
                                                 yc int default 0, rc int default 0, st boolean default false)
returns jsonb language sql immutable as $$
  select coalesce(jsonb_agg(jsonb_build_object('k', k, 'n', n, 'p', pts)) filter (where n > 0), '[]'::jsonb)
  from (values
    ('مشاركة (أساسي)', case when st then 1 else 0 end, 3),
    ('جول', g, case when p_pos = 'GK' then g * 8 else least(g, 3) * 5 + greatest(g - 3, 0) * 7 end),
    ('بونص هاتريك أهداف', case when g >= 3 then 1 else 0 end, 6),
    ('أسيست', a, least(a, 3) * 3 + greatest(a - 3, 0) * 5),
    ('بونص هاتريك أسيست', case when a >= 3 then 1 else 0 end, 4),
    ('تصديات', sv, sv / 3),
    ('صد بلنتي', ps, ps * 4),
    ('كلين شيت', case when cs then 1 else 0 end, 8),
    ('تدخلات دفاعية', tk, tk / 5),
    ('ضيّع بلنتي', pm, -3 * pm),
    ('سب', ins, -5 * ins),
    ('جول عكسي', og, -2 * og),
    ('رجل المباراة', motm, 3 * motm),
    ('كارت أصفر', yc, -yc),
    ('كارت أحمر', rc, -2 * rc)
  ) x(k, n, pts);
$$;

-- قيمة الحدث الواحد الاسمية (للعرض بس — الحساب الحقيقي في fn_pmp)
create or replace function public.fn_event_points(p_type text, p_pos text)
returns int language sql immutable as $$
  select case p_type
    when 'goal' then case when p_pos = 'GK' then 8 else 5 end
    when 'assist' then 3 when 'penaltySave' then 4 when 'penaltyMiss' then -3
    when 'insult' then -5 when 'ownGoal' then -2 when 'motm' then 3
    when 'yellowCard' then -1 when 'redCard' then -2 else 0 end;
$$;

-- اسم الحدث بالعربي (للإشعارات)
create or replace function public.fn_event_label(p_type text)
returns text language sql immutable as $$
  select case p_type
    when 'goal' then 'جوووول ⚽' when 'assist' then 'أسيست 🎯' when 'save' then 'تصدّي 🧤'
    when 'penaltySave' then 'صدّ بلنتي 🧤' when 'penaltyMiss' then 'ضيّع بلنتي ❌' when 'tackle' then 'تدخّل دفاعي 🛡'
    when 'insult' then 'سب — خصم ٥ 🚫' when 'ownGoal' then 'جول عكسي' when 'motm' then 'رجل المباراة ⭐'
    when 'yellowCard' then 'كارت أصفر 🟨' when 'redCard' then 'كارت أحمر 🟥' when 'sub' then 'تبديل 🔁'
    else p_type end;
$$;

-- إحصائيات اللاعب (الفورمة = متوسط آخر ٣ أسابيع لعب فيها)
create or replace function public.fn_recalc_player(p_player uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.players pl set
    total_points = coalesce((select sum(x.points) from public.fn_pmp('-infinity', 'infinity', p_player) x), 0),
    goals        = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'goal'),
    assists      = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'assist'),
    clean_sheets = (select count(*) from public.fn_pmp('-infinity', 'infinity', p_player) x where x.cs),
    yellow_cards = 0,
    form = coalesce((
      select round(avg(w.pts)::numeric, 1) from (
        select m.week, sum(x.points) as pts
        from public.fn_pmp('-infinity', 'infinity', p_player) x join public.matches m on m.id = x.match_id
        group by m.week order by m.week desc limit 3
      ) w), 0)
  where pl.id = p_player;
end $$;

-- ┌─────────────────────────────────────────────────────────────┐
-- │ وضع التجربة: true = مواعيد الجولة مش بتقفل حاجة عشان نجرّب فورًا │
-- │   • التشكيلة مفتوحة طول الجولة (الديدلاين = نهايتها)           │
-- │   • الماتش يتعمل في أي وقت (مفيش "بعد ساعة" ولا فاصل السبت)     │
-- │   • التوقّع مفتوح لحد ما الماتش يخلص · الاعتماد بعد ١٠ دقايق     │
-- │   • التقييم ٣٠ دقيقة بعد الماتش · تغيير المنطقة في أي وقت        │
-- │   • تشكيلة الجولة تتعتمد من غير ما تستنى الجولة تخلص            │
-- │ ⚠️ قبل الإطلاق: خليها false وشغّل الملف تاني                    │
-- │    (ومعاها kTestMode في lib/core/app_mode.dart)                │
-- └─────────────────────────────────────────────────────────────┘
create or replace function public.fn_test_mode()
returns boolean language sql immutable as $$ select false; $$;  -- TEST_MODE

-- قفل التوقّع/الاختيار قبل الماتش (ساعة · صفر في التجربة)
create or replace function public.fn_lock_lead()
returns interval language sql immutable as $$
  select case when public.fn_test_mode() then interval '0' else interval '1 hour' end;
$$;

-- أقل مهلة لإضافة ماتش (أو تغيير ميعاده) قبل ما يبدأ: ساعتين — عشان اليوزرز يلحقوا يختاروا من لاعيبته (صفر في التجربة)
create or replace function public.fn_create_lead()
returns interval language sql immutable as $$
  select case when public.fn_test_mode() then interval '0' else interval '2 hours' end;
$$;

-- مهلة اعتماد الماتش بعد ما يخلص: لو محدش من الفريقين اعترض والأدمن ماحكمش، بيتعتمد لوحده بعدها
-- (٤ ساعات · ١٠ دقايق في التجربة)
create or replace function public.fn_review_window()
returns interval language sql immutable as $$
  select case when public.fn_test_mode() then interval '10 minutes' else interval '4 hours' end;
$$;

-- تقييم اللاعيبة + تصويت رجل المباراة بعد الماتش (٢٤ ساعة · ٣٠ دقيقة في التجربة عشان النتيجة تبان)
create or replace function public.fn_rating_window()
returns interval language sql immutable as $$
  select case when public.fn_test_mode() then interval '30 minutes' else interval '24 hours' end;
$$;

-- نهاية الجولة اللي فيها وقت معيّن = أول سبت الساعة ٨ الصبح (القاهرة) بعده أو عنده.
-- الجولة = [السبت ٤ العصر , السبت اللي بعده ٨ الصبح] · ديدلاين التشكيلات = السبت ٣ العصر قبل بدايتها.
-- السبت من ٨ الصبح لـ ٤ العصر فاصل: مفيش ماتشات (trg_matches_gap) — فأي "(r - 7 أيام , r]" = ماتشات الجولة بالظبط.
-- (نفس WeekWindow في Dart)
create or replace function public.fn_week_cutoff(ts timestamptz)
returns timestamptz language sql stable as $$
  select case when public.fn_test_mode() then timestamptz '2099-12-31 06:00:00+00'   -- التجربة: جولة واحدة لكل حاجة
         else (case when c < l then c + interval '7 days' else c end) at time zone 'Africa/Cairo' end
  from (select ts at time zone 'Africa/Cairo' as l) x,
  lateral (select l::date + ((6 - extract(isodow from l)::int + 7) % 7) * interval '1 day'
                  + interval '8 hours' as c) y;
$$;

-- أول ماتشات الجولة (للحسابات): أسبوع قبل نهايتها · في التجربة كل الماتشات من الأول
create or replace function public.fn_round_from(p_round timestamptz)
returns timestamptz language sql immutable as $$
  select case when public.fn_test_mode() then timestamptz '-infinity' else p_round - interval '7 days' end;
$$;

-- بداية جولة (بنهايتها) = السبت اللي قبلها ٤ العصر
create or replace function public.fn_round_start(p_round timestamptz)
returns timestamptz language sql immutable as $$ select p_round - interval '6 days 16 hours'; $$;

-- ديدلاين جولة (بنهايتها) = قبل بدايتها بساعة (السبت ٣ العصر)
create or replace function public.fn_round_deadline(p_round timestamptz)
returns timestamptz language sql immutable as $$
  select case when public.fn_test_mode() then p_round else p_round - interval '6 days 17 hours' end;
$$;

-- الجولة اللي التشكيلات مفتوحة ليها دلوقتي (أقرب جولة ديدلاينها لسه مجاش)
create or replace function public.fn_open_round()
returns timestamptz language sql stable as $$
  select case when now() < public.fn_round_deadline(c) then c else c + interval '7 days' end
  from (select public.fn_week_cutoff(now()) as c) x;
$$;

-- السبت من ٨ الصبح لـ ٤ العصر (بتوقيت القاهرة) = بين جولتين
create or replace function public.fn_in_round_gap(ts timestamptz)
returns boolean language sql stable as $$
  select not public.fn_test_mode() and extract(isodow from l) = 6 and l::time > time '08:00' and l::time < time '16:00'
  from (select ts at time zone 'Africa/Cairo' as l) x;
$$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 3) LINEUPS                                                     ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.lineups (
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'bench',   -- starting | bench
  primary key (match_id, player_id)
);
alter table public.lineups enable row level security;

drop policy if exists "lineups read" on public.lineups;
create policy "lineups read" on public.lineups for select to authenticated using (true);
drop policy if exists "lineups manager write" on public.lineups;
create policy "lineups manager write" on public.lineups for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
-- المنظّم: تشكيلة ماتشاته بس، ومن لاعيبة الفريقين بس
drop policy if exists "lineups organizer write" on public.lineups;
create policy "lineups organizer write" on public.lineups for all to authenticated
  using (public.fn_organizes(match_id))
  with check (public.fn_organizes(match_id) and exists (
    select 1 from public.players pl join public.matches m on m.id = lineups.match_id
    where pl.id = lineups.player_id and pl.team = any(m.teams)));


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 4) PICKS                                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.picks (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null default 'starting',   -- starting | bench
  is_captain boolean not null default false,
  is_vice    boolean not null default false,
  primary key (user_id, match_id, player_id)
);
alter table public.picks add column if not exists is_vice boolean not null default false;
alter table public.picks add column if not exists saved_at timestamptz not null default now();
create index if not exists picks_match on public.picks(match_id);
create index if not exists picks_player on public.picks(player_id);
alter table public.picks enable row level security;

-- تشكيلتك تشوفها دايمًا. تشكيلات الناس تبان بعد ما الماتش يقفل بس (محدش ينقل من حد).
drop policy if exists "picks read" on public.picks;
create policy "picks read" on public.picks for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists(select 1 from public.matches m where m.id = match_id and m.date_time - public.fn_lock_lead() <= now())
);
-- مفيش كتابة مباشرة: الحفظ بدالة save_picks (قسم 15) عشان التحقّق يبقى في السيرفر.
drop policy if exists "picks own write" on public.picks;

-- تشكيلة الجولة: ٧ لاعيبة من أي فرق في منطقتك (٥ أساسي بحارس + ٢ احتياطي) + كابتن وكابتن بديل.
-- (picks القديمة = تشكيلات الماتش الواحد قبل نظام الجولة — نقطها المعتمدة لسه في الإجمالي)
create table if not exists public.round_picks (
  user_id    uuid references public.profiles(id) on delete cascade,
  round_end  timestamptz not null,
  player_id  uuid references public.players(id) on delete cascade,
  status     text not null check (status in ('starting', 'bench')),
  is_captain boolean not null default false,
  is_vice    boolean not null default false,
  saved_at   timestamptz not null default now(),
  primary key (user_id, round_end, player_id)
);
create index if not exists round_picks_round on public.round_picks(round_end, player_id);
alter table public.round_picks enable row level security;
-- تشكيلتك دايمًا، وتشكيلات الناس بعد الديدلاين. مفيش كتابة مباشرة (save_round_picks).
drop policy if exists "round picks read" on public.round_picks;
create policy "round picks read" on public.round_picks for select to authenticated using (
  user_id = auth.uid() or public.is_manager() or now() >= public.fn_round_deadline(round_end)
);

-- نقط كل يوزر في كل جولة: points = مباشر (كل الماتشات غير الملغية) · final_points = المعتمد بس
create table if not exists public.user_round_points (
  user_id      uuid references public.profiles(id) on delete cascade,
  round_end    timestamptz not null,
  points       int not null default 0,
  final_points int not null default 0,
  primary key (user_id, round_end)
);
create index if not exists urp_round on public.user_round_points(round_end);
alter table public.user_round_points enable row level security;
drop policy if exists "urp read" on public.user_round_points;
create policy "urp read" on public.user_round_points for select to authenticated using (true);
drop trigger if exists picks_recalc on public.picks;
drop trigger if exists profile_recalc on public.profiles;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 5) WEEK STATS                                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- نقط كل لاعب في كل ماتش في فترة (الماتشات الملغية برا) — الأساس اللي كل حاجة بتتحسب منه.
-- p_player: لاعب واحد بس (أسرع). cs = خد كلين شيت.
create or replace function public.fn_pmp(p_from timestamptz, p_to timestamptz, p_player uuid default null)
returns table(match_id uuid, player_id uuid, points int, goals int, cs boolean, items jsonb)
language sql stable security definer set search_path = public as $$
  with ms as (
    select m.* from public.matches m
    where m.date_time > p_from and m.date_time <= p_to and m.review_status <> 'void'
  ), ev as (
    select e.match_id, e.player_id,
      (count(*) filter (where e.type = 'goal'))::int as g,
      (count(*) filter (where e.type = 'assist'))::int as a,
      (count(*) filter (where e.type = 'save'))::int as sv,
      (count(*) filter (where e.type = 'penaltySave'))::int as ps,
      (count(*) filter (where e.type = 'penaltyMiss'))::int as pm,
      (count(*) filter (where e.type = 'tackle'))::int as tk,
      (count(*) filter (where e.type = 'insult'))::int as ins,
      (count(*) filter (where e.type = 'ownGoal'))::int as og,
      (count(*) filter (where e.type = 'motm'))::int as motm,
      (count(*) filter (where e.type = 'yellowCard'))::int as yc,
      (count(*) filter (where e.type = 'redCard'))::int as rc
    from public.events e join ms on ms.id = e.match_id
    where p_player is null or e.player_id = p_player
    group by e.match_id, e.player_id
  ), st as (
    -- نقط المشاركة: كل لاعب أساسي في تشكيلة الماتش
    select ms.id as match_id, l.player_id from ms
    join public.lineups l on l.match_id = ms.id and l.status = 'starting'
    where p_player is null or l.player_id = p_player
  ), cs as (
    -- الكلين شيت: الحارس الأساسي لفريق استقبل ٤ أهداف أو أقل في ماتش خلص
    select ms.id as match_id, l.player_id from ms
    join public.lineups l on l.match_id = ms.id and l.status = 'starting'
    join public.players pl on pl.id = l.player_id and pl.position = 'GK'
    where ms.status = 'finished' and ms.score_a is not null and ms.score_b is not null
      and (p_player is null or l.player_id = p_player)
      and ((pl.team = ms.teams[1] and ms.score_b <= 4) or (pl.team = ms.teams[2] and ms.score_a <= 4))
  ), k as (
    select ev.match_id, ev.player_id from ev union select st.match_id, st.player_id from st
  ), j as (
    select k.match_id, k.player_id,
      coalesce(ev.g, 0) as g, coalesce(ev.a, 0) as a, coalesce(ev.sv, 0) as sv, coalesce(ev.ps, 0) as ps,
      coalesce(ev.pm, 0) as pm, coalesce(ev.tk, 0) as tk, coalesce(ev.ins, 0) as ins, coalesce(ev.og, 0) as og,
      coalesce(ev.motm, 0) as motm, coalesce(ev.yc, 0) as yc, coalesce(ev.rc, 0) as rc,
      cs.player_id is not null as cs, st.player_id is not null as st
    from k
    left join ev on ev.match_id = k.match_id and ev.player_id = k.player_id
    left join st on st.match_id = k.match_id and st.player_id = k.player_id
    left join cs on cs.match_id = k.match_id and cs.player_id = k.player_id
  )
  select j.match_id, j.player_id,
    public.fn_score_points(pl.position, j.g, j.a, j.sv, j.ps, j.pm, j.tk, j.ins, j.og, j.motm, j.cs, j.yc, j.rc, j.st),
    j.g, j.cs,
    public.fn_score_items(pl.position, j.g, j.a, j.sv, j.ps, j.pm, j.tk, j.ins, j.og, j.motm, j.cs, j.yc, j.rc, j.st)
  from j join public.players pl on pl.id = j.player_id;
$$;

-- (للشاشة) نقط لاعيبة في جولة: المباشر والمعتمد، لعب ولا لأ، والتفصيل
create or replace function public.round_player_points(p_round timestamptz, p_players uuid[])
returns table(player_id uuid, points int, final_points int, played boolean, played_final boolean, items jsonb)
language sql stable security definer set search_path = public as $$
  with x as (
    select x.*, m.review_status = 'approved' as ok
    from public.fn_pmp(public.fn_round_from(p_round), p_round) x join public.matches m on m.id = x.match_id
    where x.player_id = any(p_players)
  ), it as (
    select x.player_id, i->>'k' as k, sum((i->>'n')::int) as n, sum((i->>'p')::int) as p
    from x cross join lateral jsonb_array_elements(x.items) i group by x.player_id, i->>'k'
  )
  select x.player_id, sum(x.points)::int, (coalesce(sum(x.points) filter (where x.ok), 0))::int,
    true, bool_or(x.ok),
    coalesce((select jsonb_agg(jsonb_build_object('k', it.k, 'n', it.n, 'p', it.p) order by it.p desc)
              from it where it.player_id = x.player_id), '[]'::jsonb)
  from x group by x.player_id;
$$;

create or replace function public.player_week_points(w int)
returns table(id uuid, name text, team text, "position" text, points bigint)
language sql stable as $$
  select pl.id, pl.name, pl.team, pl.position, sum(x.points)::bigint as points
  from public.fn_pmp('-infinity', 'infinity') x
  join public.matches m on m.id = x.match_id and m.week = w
  join public.players pl on pl.id = x.player_id
  group by pl.id, pl.name, pl.team, pl.position
  having sum(x.points) <> 0
  order by points desc;
$$;
grant execute on function public.player_week_points(int) to authenticated;

create or replace function public.player_gw_stats(w int)
returns table(id uuid, points bigint, owners bigint, ownership numeric,
              transfers_in bigint, transfers_out bigint)
language sql stable security definer set search_path = public as $$
  with cur as (
    select distinct pk.user_id, pk.player_id from public.picks pk
    join public.matches m on m.id = pk.match_id where m.week = w
  ), prev as (
    select distinct pk.user_id, pk.player_id from public.picks pk
    join public.matches m on m.id = pk.match_id where m.week = w - 1
  ), total as (
    select greatest(count(distinct user_id), 1) as n from cur
  )
  select pl.id,
    coalesce((select sum(x.points) from public.fn_pmp('-infinity', 'infinity', pl.id) x
              join public.matches m on m.id = x.match_id where m.week = w), 0)::bigint,
    (select count(*) from cur c where c.player_id = pl.id)::bigint,
    round((select count(*) from cur c where c.player_id = pl.id) * 100.0 / (select n from total), 1),
    (select count(*) from cur c where c.player_id = pl.id and not exists (
       select 1 from prev p where p.user_id = c.user_id and p.player_id = pl.id))::bigint,
    (select count(*) from prev p where p.player_id = pl.id and not exists (
       select 1 from cur c where c.user_id = p.user_id and c.player_id = pl.id))::bigint
  from public.players pl;
$$;
grant execute on function public.player_gw_stats(int) to authenticated;

create or replace function public.player_history(p uuid)
returns table(gw int, points bigint)
language sql stable as $$
  select m.week, coalesce(sum(x.points), 0)::bigint
  from public.fn_pmp('-infinity', 'infinity', p) x
  join public.matches m on m.id = x.match_id
  group by m.week order by m.week;
$$;
grant execute on function public.player_history(uuid) to authenticated;

-- نقاط كل لاعب في فترة + صورته (صورة اللاعب، ولو مفيش صورة اليوزر اللي وثّقه) + موثّق ولا لأ
-- p_zone: منطقة معيّنة بس · null = كل المناطق (للموسم)
drop function if exists public.player_points_between(timestamptz, timestamptz);
create or replace function public.player_points_between(p_from timestamptz, p_to timestamptz, p_zone int default null)
returns table(id uuid, name text, team text, "position" text, points bigint,
              image_url text, verified boolean)
language sql stable security definer set search_path = public as $$
  select pl.id, pl.name, pl.team, pl.position,
    sum(x.points)::bigint as points,
    coalesce(pl.image_url, (select pr.photo_url from public.profiles pr where pr.id = pl.user_id)),
    pl.user_id is not null
  from public.fn_pmp(p_from, p_to) x
  join public.matches m on m.id = x.match_id
    and (p_zone is null or m.zone_id = p_zone)
  join public.players pl on pl.id = x.player_id
  group by pl.id, pl.name, pl.team, pl.position, pl.image_url, pl.user_id
  having sum(x.points) <> 0
  order by points desc, pl.name;
$$;
grant execute on function public.player_points_between(timestamptz, timestamptz, int) to authenticated;

-- الامتلاك الحقيقي في الجولة (security definer: التشكيلات مخفية قبل القفل بس الأرقام الإجمالية مسموحة)
create or replace function public.player_window_stats(p_from timestamptz, p_to timestamptz)
returns table(id uuid, points bigint, owners bigint, ownership numeric,
              transfers_in bigint, transfers_out bigint, managers bigint)
language sql stable security definer set search_path = public as $$
  with cur as (
    select distinct rp.user_id, rp.player_id from public.round_picks rp
    where rp.round_end > p_from and rp.round_end <= p_to
  ), prev as (
    select distinct rp.user_id, rp.player_id from public.round_picks rp
    where rp.round_end > p_from - interval '7 days' and rp.round_end <= p_from
  ), total as (
    select count(distinct user_id) as n from cur
  ), pts as (
    select x.player_id, sum(x.points) as p from public.fn_pmp(p_from, p_to) x group by x.player_id
  ), own as (
    select cur.player_id, count(*) as n from cur group by cur.player_id
  ), tin as (
    select c.player_id, count(*) as n from cur c
    left join prev p on p.user_id = c.user_id and p.player_id = c.player_id
    where p.user_id is null group by c.player_id
  ), tout as (
    select p.player_id, count(*) as n from prev p
    left join cur c on c.user_id = p.user_id and c.player_id = p.player_id
    where c.user_id is null group by p.player_id
  )
  select pl.id, coalesce(pts.p, 0)::bigint, coalesce(own.n, 0)::bigint,
    case when total.n = 0 then 0 else round(coalesce(own.n, 0) * 100.0 / total.n, 1) end,
    coalesce(tin.n, 0)::bigint, coalesce(tout.n, 0)::bigint, total.n::bigint
  from public.players pl
  cross join total
  left join pts on pts.player_id = pl.id
  left join own on own.player_id = pl.id
  left join tin on tin.player_id = pl.id
  left join tout on tout.player_id = pl.id;
$$;
grant execute on function public.player_window_stats(timestamptz, timestamptz) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 6) NOTIFICATIONS                                               ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  body       text not null default '',
  kind       text not null default 'event',   -- lineup | match | event | status | booking | badge | vote | challenge
  match_id   uuid references public.matches(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.notifications add column if not exists kind text not null default 'event';
alter table public.notifications add column if not exists user_id uuid references public.profiles(id) on delete cascade;
-- الجمهور: all = الكل · user = يوزر واحد (user_id) · match = متابعين الماتش (match_id)
alter table public.notifications add column if not exists audience text not null default 'all';
update public.notifications set audience = 'user' where user_id is not null and audience = 'all';
create index if not exists notifications_created on public.notifications(created_at desc);
create index if not exists notifications_user on public.notifications(user_id);
create index if not exists notifications_match on public.notifications(match_id);
alter table public.notifications add column if not exists zone_id int references public.zones(id);

-- أي صف فيه user_id يبقى موجّه لليوزر ده بس
create or replace function public.trg_notifications_audience()
returns trigger language plpgsql as $$
begin
  if new.user_id is not null then
    new.audience := 'user';
  elsif new.audience = 'user' then
    raise exception 'إشعار موجّه من غير user_id';   -- عمره ما يتحوّل للكل بالغلط
  elsif new.audience = 'match' and new.match_id is null then
    raise exception 'إشعار متابعين من غير match_id';
  elsif new.audience = 'zone' and new.zone_id is null then
    raise exception 'إشعار منطقة من غير zone_id';
  elsif new.audience not in ('all', 'match', 'zone') then
    raise exception 'audience غلط: %', new.audience;
  end if;
  return new;
end $$;
drop trigger if exists notifications_audience on public.notifications;
create trigger notifications_audience before insert on public.notifications
for each row execute function public.trg_notifications_audience();

alter table public.notifications enable row level security;
-- (سياسة القراءة بتتعمل في قسم 12 بعد جدول المتابعة)
drop policy if exists "notifications manager write" on public.notifications;
create policy "notifications manager write" on public.notifications
  for insert to authenticated with check (public.is_manager());

-- إشعار عن ماتش: لأهل منطقته بس (ماتش من غير منطقة مالوش إشعار)
create or replace function public.fn_notify_match(p_match uuid, p_title text, p_body text, p_kind text)
returns void language sql security definer set search_path = public as $$
  insert into public.notifications (title, body, kind, match_id, audience, zone_id)
  select p_title, p_body, p_kind, m.id, 'zone', m.zone_id
  from public.matches m where m.id = p_match and m.zone_id is not null;
$$;




-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 7) POLLS                                                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.polls (
  id         uuid primary key default gen_random_uuid(),
  kind       text not null,        -- goal_week | save_week | goal_season | save_season | totw_tie
  question   text not null default '',
  active     boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.polls add column if not exists window_end timestamptz;   -- الجولة (للتعادل)
alter table public.polls add column if not exists closes_at  timestamptz;   -- بيتقفل لوحده
alter table public.polls add column if not exists slots      int not null default 1; -- كام فايز
alter table public.polls add column if not exists zone_id    int references public.zones(id); -- تعادل تشكيلة منطقة

create table if not exists public.poll_options (
  id        uuid primary key default gen_random_uuid(),
  poll_id   uuid references public.polls(id) on delete cascade,
  label     text not null,
  player_id uuid references public.players(id) on delete set null
);
alter table public.poll_options add column if not exists video_url text;   -- لينك فيديو الهدف/التصدّي
alter table public.poll_options add column if not exists match_id uuid references public.matches(id) on delete set null;

create table if not exists public.poll_votes (
  poll_id    uuid references public.polls(id) on delete cascade,
  option_id  uuid references public.poll_options(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (poll_id, user_id)
);
create index if not exists poll_votes_option on public.poll_votes(option_id);
create index if not exists poll_options_poll on public.poll_options(poll_id);
create index if not exists polls_kind on public.polls(kind, created_at desc);

alter table public.polls        enable row level security;
alter table public.poll_options enable row level security;
alter table public.poll_votes   enable row level security;

drop policy if exists "polls read" on public.polls;
create policy "polls read" on public.polls for select to authenticated using (true);
drop policy if exists "polls manager write" on public.polls;
create policy "polls manager write" on public.polls for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "poll_options read" on public.poll_options;
create policy "poll_options read" on public.poll_options for select to authenticated using (true);
drop policy if exists "poll_options manager write" on public.poll_options;
create policy "poll_options manager write" on public.poll_options for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

drop policy if exists "poll_votes read" on public.poll_votes;
create policy "poll_votes read" on public.poll_votes for select to authenticated using (true);
drop policy if exists "poll_votes own write" on public.poll_votes;
-- اليوزر يصوّت بنفسه، على تصويت مفتوح ومعدّاش ميعاد قفله، ولاختيار من نفس التصويت.
create policy "poll_votes own write" on public.poll_votes for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id and not public.fn_is_zone_manager()
    and exists (select 1 from public.polls p where p.id = poll_id and p.active
                and (p.closes_at is null or p.closes_at > now()))
    and exists (select 1 from public.poll_options o where o.id = option_id and o.poll_id = poll_votes.poll_id));




-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 8) SECURITY & ADMIN                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- حماية البروفايل: اليوزر ميقدرش يغيّر دوره ولا نقطه ولا مين دعاه من التطبيق.
-- (الدوال بتاعة السيرفر بتشتغل بصلاحية postgres فمش بتتأثّر)
create or replace function public.trg_profiles_guard()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.role := 'user';
      new.total_points := 0;
      new.referred_by := null;
      new.badges_dirty := false;
      new.low_picks := 0;
      new.avg_own := 100;
      new.is_active := true;
      new.zone_changed_at := case when new.zone_id is null then null else now() end;
      new.ref_code := upper(substr(md5(gen_random_uuid()::text), 1, 6));
    else
      new.role := old.role;
      new.total_points := old.total_points;
      new.referred_by := old.referred_by;
      new.badges_dirty := old.badges_dirty;
      new.ref_code := old.ref_code;
      new.email := old.email;
      new.low_picks := old.low_picks;
      new.avg_own := old.avg_own;
      new.zone_id := old.zone_id;                 -- بـ set_my_zone بس
      new.is_active := old.is_active;             -- الحظر من الأدمن بس
      new.zone_changed_at := old.zone_changed_at;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists profiles_guard on public.profiles;
create trigger profiles_guard before insert or update on public.profiles
for each row execute function public.trg_profiles_guard();

-- الخصوصية: الإيميل والموبايل وتوكن الإشعارات مخفيين عن باقي اليوزرز.
-- بروفايلك كامل بـ my_profile()، والمدير بـ admin_users().
revoke select on public.profiles from anon, authenticated;
grant select (id, name, role, photo_url, total_points, created_at, is_active, team,
              league_id, position, captain_id, zone_id) on public.profiles to authenticated;

-- تغيير منطقتي: أول مرة في أي وقت، بعدها مرة كل ٣٠ يوم. المنظّم لازم يكلّم الإدارة (فرقه في منطقته).
create or replace function public.set_my_zone(p_zone int)
returns void language plpgsql security definer set search_path = public as $$
declare me public.profiles;
begin
  select * into me from public.profiles where id = auth.uid();
  if not found then raise exception 'سجّل دخولك الأول'; end if;
  if not exists (select 1 from public.zones where id = p_zone) then raise exception 'المنطقة مش موجودة'; end if;
  if me.zone_id = p_zone then return; end if;
  if me.role = 'organizer' and me.zone_id is not null then
    raise exception 'المدير ميقدرش يغيّر منطقته — كلّم الإدارة';
  end if;
  if me.zone_id is not null and me.zone_changed_at > now() - interval '30 days' and not public.fn_test_mode() then
    raise exception 'تقدر تغيّر منطقتك مرة كل ٣٠ يوم';
  end if;
  update public.profiles set zone_id = p_zone, zone_changed_at = now() where id = me.id;
end $$;
grant execute on function public.set_my_zone(int) to authenticated;

create or replace function public.my_profile()
returns setof public.profiles language sql stable security definer set search_path = public as $$
  select * from public.profiles where id = auth.uid();
$$;
grant execute on function public.my_profile() to authenticated;

-- p_query: بحث بالاسم/الإيميل/الموبايل · p_role: user | organizer | manager (اختياري)
drop function if exists public.admin_users();
drop function if exists public.admin_users(text, text, int);
create or replace function public.admin_users(p_query text default null, p_role text default null,
                                              p_limit int default 100)
returns table(id uuid, name text, email text, phone text, role text, total_points int,
              photo_url text, created_at timestamptz, zone_id int, is_active boolean)
language plpgsql stable security definer set search_path = public as $$
declare q text := nullif(trim(coalesce(p_query, '')), '');
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query select p.id, p.name, p.email, p.phone, p.role, p.total_points, p.photo_url, p.created_at, p.zone_id,
      p.is_active
    from public.profiles p
    where (q is null or p.name ilike '%' || q || '%' or p.email ilike '%' || q || '%' or p.phone like '%' || q || '%')
      and (p_role is null or p.role = p_role)
    order by p.total_points desc
    limit least(greatest(p_limit, 1), 500);
end $$;
grant execute on function public.admin_users(text, text, int) to authenticated;

-- الأدمن يخلّي يوزر مدير منطقة أو يرجّعه يوزر. الأدمن الجديد بيتعمل من Supabase بس (مش من التطبيق):
--   update public.profiles set role = 'manager' where email = '...';
create or replace function public.set_user_role(uid uuid, new_role text)
returns void language plpgsql security definer set search_path = public as $$
declare t public.profiles;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  if new_role not in ('user', 'organizer') then raise exception 'الأدمن بيتضاف من Supabase بس'; end if;
  select * into t from public.profiles where id = uid;
  if not found then raise exception 'اليوزر مش موجود'; end if;
  if t.role = 'manager' then raise exception 'مينفعش تغيّر دور أدمن من التطبيق'; end if;
  if new_role = 'organizer' then
    if t.zone_id is null then raise exception 'اليوزر لازم يختار منطقته الأول'; end if;
    if exists (select 1 from public.players where user_id = uid) then
      raise exception 'اليوزر ده موثّق كلاعب — فك التوثيق الأول (المدير مش بيلعب)';
    end if;
  end if;
  update public.profiles set role = new_role where id = uid;
  if new_role = 'organizer' then perform public.fn_leave_fantasy(uid); end if;
  perform public.fn_admin_log('set_role', uid::text, jsonb_build_object('role', new_role, 'name', t.name));
end; $$;
grant execute on function public.set_user_role(uuid, text) to authenticated;

-- كود الدعوة: اليوزر الجديد يكتب كود صاحبه (مرة واحدة، خلال أول ٧ أيام)
create or replace function public.apply_referral(p_code text)
returns void language plpgsql security definer set search_path = public as $$
declare me public.profiles; ref uuid;
begin
  select * into me from public.profiles where id = auth.uid();
  if not found then raise exception 'سجّل دخولك الأول'; end if;
  if me.referred_by is not null then raise exception 'كتبت كود دعوة قبل كده'; end if;
  if me.created_at < now() - interval '7 days' then raise exception 'كود الدعوة للحسابات الجديدة بس'; end if;
  select id into ref from public.profiles where ref_code = upper(trim(p_code));
  if ref is null then raise exception 'الكود مش صحيح'; end if;
  if ref = me.id then raise exception 'ماينفعش تكتب كودك'; end if;
  update public.profiles set referred_by = ref where id = me.id;
  update public.profiles set badges_dirty = true where id = ref;
end $$;
grant execute on function public.apply_referral(text) to authenticated;

-- صور البروفايل: كل يوزر يرفع في فولدر باسمه بس
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "avatars read" on storage.objects;
create policy "avatars read" on storage.objects for select using (bucket_id = 'avatars');
drop policy if exists "avatars own write" on storage.objects;
create policy "avatars own write" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "avatars own delete" on storage.objects;
create policy "avatars own delete" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- صور اللاعيبة: المدير بس
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('player-photos', 'player-photos', true, 3145728, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "player photos read" on storage.objects;
create policy "player photos read" on storage.objects for select using (bucket_id = 'player-photos');
drop policy if exists "player photos manager write" on storage.objects;
create policy "player photos manager write" on storage.objects for insert to authenticated
  with check (bucket_id = 'player-photos' and public.is_manager());
drop policy if exists "player photos manager delete" on storage.objects;
create policy "player photos manager delete" on storage.objects for delete to authenticated
  using (bucket_id = 'player-photos' and public.is_manager());


