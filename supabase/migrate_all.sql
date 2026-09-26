-- ═══════════════════════════════════════════════════════════════
-- الخماسي — كل الـ migrations في ملف واحد (شغّله مرة واحدة، وتقدر تعيده)
-- Supabase Dashboard → SQL Editor → New query → الصق الكل → Run
--
-- الأقسام بالترتيب (الترتيب مهم):
--    1) schema             — الجداول الأساسية + الأعمدة الجديدة
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
create index if not exists events_player on public.events(player_id);

-- الدخول برقم الموبايل: يحوّل الرقم لإيميل
create or replace function public.email_for_phone(p text)
returns text language sql security definer set search_path = public as $$
  select email from public.profiles where phone = p limit 1;
$$;
grant execute on function public.email_for_phone(text) to anon, authenticated;

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

drop policy if exists "members read"   on public.league_members;
drop policy if exists "members insert" on public.league_members;
drop policy if exists "members delete" on public.league_members;
create policy "members read"   on public.league_members for select to authenticated using (true);
create policy "members insert" on public.league_members for insert to authenticated with check (auth.uid() = user_id);


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
     and exists(select 1 from public.matches m where m.id = p_match and m.date_time - interval '15 minutes' <= now());
end $$;

drop policy if exists "players manager write" on public.players;
create policy "players manager write" on public.players for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
-- المنظّم يضيف لاعيبة ويعدّل اللي هو ضافهم (الإحصائيات والتوثيق محميين بـ trigger)
drop policy if exists "players organizer insert" on public.players;
create policy "players organizer insert" on public.players for insert to authenticated
  with check (public.is_organizer());
drop policy if exists "players organizer update" on public.players;
create policy "players organizer update" on public.players for update to authenticated
  using (created_by = auth.uid() and public.is_organizer()) with check (created_by = auth.uid());

drop policy if exists "matches manager write" on public.matches;
create policy "matches manager write" on public.matches for all to authenticated
  using (public.is_manager()) with check (public.is_manager());
drop policy if exists "matches organizer insert" on public.matches;
create policy "matches organizer insert" on public.matches for insert to authenticated
  with check (public.is_organizer());
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

-- نقاط الحدث حسب النوع والمركز (نفس PointsEngine في Dart بالظبط)
create or replace function public.fn_event_points(p_type text, p_pos text)
returns int language sql immutable as $$
  select case
    when p_type = 'appearance'  then 1
    when p_type = 'goal'        then case when p_pos in ('GK','DEF') then 6 when p_pos='MID' then 5 else 4 end
    when p_type = 'assist'      then 3
    when p_type = 'cleanSheet'  then case when p_pos in ('GK','DEF') then 4 when p_pos='MID' then 1 else 0 end
    when p_type = 'save'        then 1
    when p_type = 'penaltySave' then 5
    when p_type = 'motm'        then 3     -- رجل المباراة (تصويت الجمهور)
    when p_type = 'bonus'       then 3
    when p_type = 'yellowCard'  then -1
    when p_type = 'redCard'     then -3
    when p_type = 'ownGoal'     then -2
    when p_type = 'penaltyMiss' then -2
    else 0
  end;
$$;

-- اسم الحدث بالعربي (للإشعارات)
create or replace function public.fn_event_label(p_type text)
returns text language sql immutable as $$
  select case p_type
    when 'goal' then 'جوووول ⚽' when 'assist' then 'أسيست 🎯' when 'cleanSheet' then 'شباك نظيفة 🧤'
    when 'save' then 'تصدّي 🧤' when 'penaltySave' then 'صدّ بلنتي 🧤' when 'motm' then 'رجل المباراة ⭐'
    when 'bonus' then 'بونص ➕' when 'yellowCard' then 'كارت أصفر 🟨' when 'redCard' then 'كارت أحمر 🟥'
    when 'ownGoal' then 'جول عكسي' when 'penaltyMiss' then 'أضاع بلنتي' else p_type end;
$$;

-- إحصائيات اللاعب من أحداثه (الفورمة = متوسط آخر ٣ جولات)
create or replace function public.fn_recalc_player(p_player uuid)
returns void language sql security definer set search_path = public as $$
  update public.players pl set
    total_points = coalesce((
      select sum(public.fn_event_points(e.type, pl.position))
      from public.events e where e.player_id = pl.id), 0),
    goals        = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'goal'),
    assists      = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'assist'),
    clean_sheets = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'cleanSheet'),
    yellow_cards = (select count(*) from public.events e where e.player_id = pl.id and e.type = 'yellowCard'),
    form = coalesce((
      select round(avg(w.pts)::numeric, 1) from (
        select m.week, sum(public.fn_event_points(e.type, pl.position)) as pts
        from public.events e join public.matches m on m.id = e.match_id
        where e.player_id = pl.id
        group by m.week order by m.week desc limit 3
      ) w), 0)
  where pl.id = p_player;
$$;

-- نهاية الجولة اللي فيها وقت معيّن = أول سبت الساعة ٤ العصر (القاهرة) بعده أو عنده.
-- الجولة = (السبت ٤ العصر , السبت اللي بعده ٤ العصر] · ديدلاين التشكيلات = السبت ١٢ الضهر قبل بدايتها.
-- (نفس WeekWindow في Dart: الماتش في الجولة لو start < date_time <= cutoff)
create or replace function public.fn_week_cutoff(ts timestamptz)
returns timestamptz language sql stable as $$
  select (case when c < l then c + interval '7 days' else c end) at time zone 'Africa/Cairo'
  from (select ts at time zone 'Africa/Cairo' as l) x,
  lateral (select l::date + ((6 - extract(isodow from l)::int + 7) % 7) * interval '1 day'
                  + interval '16 hours' as c) y;
$$;

-- ديدلاين جولة (بنهايتها) = قبل بدايتها بـ ٤ ساعات
create or replace function public.fn_round_deadline(p_round timestamptz)
returns timestamptz language sql immutable as $$ select p_round - interval '7 days 4 hours'; $$;

-- الجولة اللي التشكيلات مفتوحة ليها دلوقتي (أقرب جولة ديدلاينها لسه مجاش)
create or replace function public.fn_open_round()
returns timestamptz language sql stable as $$
  select case when now() < c - interval '4 hours' then c + interval '7 days' else c + interval '14 days' end
  from (select public.fn_week_cutoff(now()) as c) x;
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
  or exists(select 1 from public.matches m where m.id = match_id and m.date_time - interval '1 hour' <= now())
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
  user_id = auth.uid() or public.is_manager() or now() >= round_end - interval '7 days 4 hours'
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

create or replace function public.player_week_points(w int)
returns table(id uuid, name text, team text, "position" text, points bigint)
language sql stable as $$
  select pl.id, pl.name, pl.team, pl.position,
    coalesce(sum(public.fn_event_points(e.type, pl.position)), 0)::bigint as points
  from public.players pl
  join public.events e on e.player_id = pl.id
  join public.matches m on m.id = e.match_id and m.week = w
  group by pl.id, pl.name, pl.team, pl.position
  having coalesce(sum(public.fn_event_points(e.type, pl.position)), 0) <> 0
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
    coalesce((select sum(public.fn_event_points(e.type, pl.position))
              from public.events e join public.matches m on m.id = e.match_id
              where e.player_id = pl.id and m.week = w), 0)::bigint,
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
  select m.week, coalesce(sum(public.fn_event_points(e.type, pl.position)), 0)::bigint
  from public.events e
  join public.matches m on m.id = e.match_id
  join public.players pl on pl.id = e.player_id
  where e.player_id = p
  group by m.week order by m.week;
$$;
grant execute on function public.player_history(uuid) to authenticated;

-- نقاط كل لاعب في فترة + صورته (صورة اللاعب، ولو مفيش صورة اليوزر اللي وثّقه) + موثّق ولا لأ
-- p_zone: منطقة معيّنة (+ الماتشات العامة) · null = كل المناطق (للموسم)
drop function if exists public.player_points_between(timestamptz, timestamptz);
create or replace function public.player_points_between(p_from timestamptz, p_to timestamptz, p_zone int default null)
returns table(id uuid, name text, team text, "position" text, points bigint,
              image_url text, verified boolean)
language sql stable security definer set search_path = public as $$
  select pl.id, pl.name, pl.team, pl.position,
    sum(public.fn_event_points(e.type, pl.position))::bigint as points,
    coalesce(pl.image_url, (select pr.photo_url from public.profiles pr where pr.id = pl.user_id)),
    pl.user_id is not null
  from public.events e
  join public.matches m on m.id = e.match_id and m.date_time > p_from and m.date_time <= p_to
    and (p_zone is null or m.zone_id is null or m.zone_id = p_zone)
  join public.players pl on pl.id = e.player_id
  group by pl.id, pl.name, pl.team, pl.position, pl.image_url, pl.user_id
  having sum(public.fn_event_points(e.type, pl.position)) <> 0
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
    select e.player_id, sum(public.fn_event_points(e.type, pl.position)) as p
    from public.events e
    join public.matches m on m.id = e.match_id and m.date_time > p_from and m.date_time <= p_to
    join public.players pl on pl.id = e.player_id
    group by e.player_id
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

-- إشعار عن ماتش: لأهل منطقته بس (والماتش العام للكل)
create or replace function public.fn_notify_match(p_match uuid, p_title text, p_body text, p_kind text)
returns void language sql security definer set search_path = public as $$
  insert into public.notifications (title, body, kind, match_id, audience, zone_id)
  select p_title, p_body, p_kind, m.id, case when m.zone_id is null then 'all' else 'zone' end, m.zone_id
  from public.matches m where m.id = p_match;
$$;

do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;


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
  with check (auth.uid() = user_id
    and exists (select 1 from public.polls p where p.id = poll_id and p.active
                and (p.closes_at is null or p.closes_at > now()))
    and exists (select 1 from public.poll_options o where o.id = option_id and o.poll_id = poll_votes.poll_id));

do $$ begin
  alter publication supabase_realtime add table public.poll_votes;
exception when duplicate_object then null; end $$;


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
    raise exception 'المنظّم ميقدرش يغيّر منطقته — كلّم الإدارة';
  end if;
  if me.zone_id is not null and me.zone_changed_at > now() - interval '30 days' then
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

create or replace function public.admin_users()
returns table(id uuid, name text, email text, phone text, role text, total_points int,
              photo_url text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  return query select p.id, p.name, p.email, p.phone, p.role, p.total_points, p.photo_url, p.created_at
    from public.profiles p order by p.total_points desc;
end $$;
grant execute on function public.admin_users() to authenticated;

create or replace function public.set_user_role(uid uuid, new_role text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'not allowed'; end if;
  if new_role not in ('user', 'organizer', 'manager') then raise exception 'bad role'; end if;
  update public.profiles set role = new_role where id = uid;
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


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 9) VENUES & BOOKINGS                                           ║
-- ╚═══════════════════════════════════════════════════════════════╝

alter table public.venues add column if not exists lat        double precision;
alter table public.venues add column if not exists lng        double precision;
alter table public.venues add column if not exists phone      text;
alter table public.venues add column if not exists address    text;
alter table public.venues add column if not exists open_hour  int not null default 16;
alter table public.venues add column if not exists close_hour int not null default 24;
alter table public.venues add column if not exists photos     text[] not null default '{}';
alter table public.venues add column if not exists owner_id   uuid references public.profiles(id) on delete set null;
alter table public.venues add column if not exists maps_url   text;
alter table public.venues add column if not exists created_at timestamptz not null default now();
do $$ begin
  alter table public.venues add constraint venues_hours_chk
    check (open_hour between 0 and 23 and close_hour > open_hour and close_hour <= 30);
exception when duplicate_object then null; end $$;

-- أي يوزر يضيف ملعب ويبقى صاحبه (بحد ٥ ملاعب). صاحبه يعدّل ويحذف، والمدير يقدر على الكل.
drop policy if exists "venues manager write" on public.venues;
drop policy if exists "venues insert" on public.venues;
drop policy if exists "venues update" on public.venues;
drop policy if exists "venues delete" on public.venues;
create policy "venues insert" on public.venues for insert to authenticated with check (
  public.is_manager()
  or (owner_id = auth.uid()
      and (select count(*) from public.venues v where v.owner_id = auth.uid()) < 5)
);
create policy "venues update" on public.venues for update to authenticated
  using (owner_id = auth.uid() or public.is_manager())
  with check (owner_id = auth.uid() or public.is_manager());
create policy "venues delete" on public.venues for delete to authenticated
  using (owner_id = auth.uid() or public.is_manager());

create table if not exists public.bookings (
  id         uuid primary key default gen_random_uuid(),
  venue_id   uuid not null references public.venues(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  day        date not null,
  hour       int  not null,
  status     text not null default 'pending',   -- pending | confirmed | rejected | cancelled
  note       text,
  created_at timestamptz not null default now()
);
create unique index if not exists bookings_one_active_per_slot
  on public.bookings (venue_id, day, hour) where status in ('pending', 'confirmed');
alter table public.bookings enable row level security;

-- الحجز بيانات شخصية: يشوفه صاحبه وصاحب الملعب والمدير بس.
-- المواعيد المحجوزة لباقي الناس بتيجي من venue_slots() من غير أسماء.
drop policy if exists "bookings read" on public.bookings;
create policy "bookings read" on public.bookings for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.venues v where v.id = venue_id and v.owner_id = auth.uid())
);
drop policy if exists "bookings request" on public.bookings;
create policy "bookings request" on public.bookings for insert to authenticated
  with check (
    auth.uid() = user_id and status = 'pending' and day >= current_date
    and exists (select 1 from public.venues v
                where v.id = venue_id and hour >= v.open_hour and hour < v.close_hour)
  );

-- المواعيد المشغولة في ملعب (من غير بيانات الحاجز) — user_id بيرجع بس لو الحجز بتاعك.
create or replace function public.venue_slots(p_venue uuid, p_from date, p_to date)
returns table(id uuid, venue_id uuid, user_id uuid, day date, hour int, status text)
language sql stable security definer set search_path = public as $$
  select b.id, b.venue_id, case when b.user_id = auth.uid() then b.user_id end, b.day, b.hour, b.status
  from public.bookings b
  where b.venue_id = p_venue and b.day between p_from and p_to and b.status in ('pending', 'confirmed');
$$;
grant execute on function public.venue_slots(uuid, date, date) to authenticated;

-- قايمة حجوزات بالأسماء: mine = حجوزاتي · owner = طلبات ملاعبي · all = الكل (المدير)
create or replace function public.booking_list(p_scope text)
returns setof json language sql stable security definer set search_path = public as $$
  select json_build_object(
    'id', b.id, 'venue_id', b.venue_id, 'user_id', b.user_id, 'day', b.day, 'hour', b.hour,
    'status', b.status, 'note', b.note,
    'venues', json_build_object('name', v.name, 'owner_id', v.owner_id),
    'profiles', json_build_object('name', p.name,
       'phone', case when v.owner_id = auth.uid() or public.is_manager() then p.phone end))
  from public.bookings b
  join public.venues v on v.id = b.venue_id
  join public.profiles p on p.id = b.user_id
  where (p_scope = 'mine' and b.user_id = auth.uid())
     or (p_scope = 'owner' and v.owner_id = auth.uid())
     or (p_scope = 'all' and public.is_manager())
  order by b.day desc, b.hour desc
  limit 300;
$$;
grant execute on function public.booking_list(text) to authenticated;

create or replace function public.fmt_hour(h int)
returns text language sql immutable as $$
  select (case when h % 24 = 0 then 12 when h % 24 > 12 then h % 24 - 12 else h % 24 end)::text
         || ':00' || case when h % 24 < 12 then 'ص' else 'م' end;
$$;

create or replace function public.set_booking_status(bid uuid, new_status text)
returns void language plpgsql security definer set search_path = public as $$
declare b public.bookings; is_owner boolean;
begin
  select * into b from public.bookings where id = bid;
  if not found then raise exception 'booking not found'; end if;
  select (exists(select 1 from public.venues v where v.id = b.venue_id and v.owner_id = auth.uid())
          or public.is_manager()) into is_owner;
  if new_status = 'cancelled' and b.status in ('pending', 'confirmed')
     and (b.user_id = auth.uid() or is_owner) then
    null;
  elsif new_status in ('confirmed', 'rejected') and b.status = 'pending' and is_owner then
    null;
  else
    raise exception 'not allowed';
  end if;
  update public.bookings set status = new_status where id = bid;
end; $$;
grant execute on function public.set_booking_status(uuid, text) to authenticated;

create or replace function public.trg_booking_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare v public.venues; who text; slot text;
begin
  select * into v from public.venues where id = new.venue_id;
  slot := v.name || ' · ' || to_char(new.day, 'DD/MM') || ' الساعة ' || public.fmt_hour(new.hour);
  select coalesce(nullif(name, ''), 'يوزر') into who from public.profiles where id = new.user_id;
  if tg_op = 'INSERT' then
    if v.owner_id is not null then
      insert into public.notifications (title, body, kind, user_id)
      values ('طلب حجز جديد 📅', who || ' عايز يحجز ' || slot, 'booking', v.owner_id);
    end if;
  elsif new.status is distinct from old.status then
    if new.status = 'confirmed' then
      insert into public.notifications (title, body, kind, user_id) values ('اتأكد حجزك ✅', slot, 'booking', new.user_id);
    elsif new.status = 'rejected' then
      insert into public.notifications (title, body, kind, user_id) values ('اترفض طلب الحجز ❌', slot, 'booking', new.user_id);
    elsif new.status = 'cancelled' then
      if auth.uid() = new.user_id and v.owner_id is not null then
        insert into public.notifications (title, body, kind, user_id)
        values ('اتلغى حجز 🚫', who || ' لغى ' || slot, 'booking', v.owner_id);
      elsif auth.uid() is distinct from new.user_id then
        insert into public.notifications (title, body, kind, user_id) values ('اتلغى حجزك 🚫', slot, 'booking', new.user_id);
      end if;
    end if;
  end if;
  return new;
end; $$;
drop trigger if exists booking_notify on public.bookings;
create trigger booking_notify after insert or update on public.bookings
for each row execute function public.trg_booking_notify();

-- ── تقييمات الملاعب (نجوم + تعليق) — أي يوزر ما عدا صاحب الملعب ──
create table if not exists public.venue_reviews (
  venue_id   uuid references public.venues(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  stars      int not null check (stars between 1 and 5),
  comment    text check (comment is null or length(comment) <= 500),
  created_at timestamptz not null default now(),
  primary key (venue_id, user_id)
);
alter table public.venue_reviews enable row level security;
drop policy if exists "reviews read" on public.venue_reviews;
create policy "reviews read" on public.venue_reviews for select to authenticated using (true);
drop policy if exists "reviews own write" on public.venue_reviews;
create policy "reviews own write" on public.venue_reviews for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid()
    and not exists (select 1 from public.venues v where v.id = venue_id and v.owner_id = auth.uid()));

-- متوسط تقييم كل ملعب
create or replace function public.venue_ratings()
returns table(venue_id uuid, avg numeric, count bigint)
language sql stable as $$
  select venue_id, round(avg(stars)::numeric, 1), count(*) from public.venue_reviews group by venue_id;
$$;
grant execute on function public.venue_ratings() to authenticated;

-- التقييمات بأسماء اللي كتبوها
create or replace function public.venue_review_list(p_venue uuid)
returns table(user_id uuid, name text, photo_url text, stars int, comment text, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select r.user_id, p.name, p.photo_url, r.stars, r.comment, r.created_at
  from public.venue_reviews r join public.profiles p on p.id = r.user_id
  where r.venue_id = p_venue order by r.created_at desc limit 100;
$$;
grant execute on function public.venue_review_list(uuid) to authenticated;

create or replace function public.trg_review_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare v public.venues;
begin
  select * into v from public.venues where id = new.venue_id;
  if v.owner_id is not null and tg_op = 'INSERT' then
    insert into public.notifications (title, body, kind, user_id)
    values ('⭐ تقييم جديد لملعبك', v.name || ' · ' || repeat('★', new.stars) || coalesce(' — ' || left(new.comment, 80), ''),
            'booking', v.owner_id);
  end if;
  return new;
end $$;
drop trigger if exists review_notify on public.venue_reviews;
create trigger review_notify after insert on public.venue_reviews
for each row execute function public.trg_review_notify();

-- صور الملاعب: كل يوزر يرفع في فولدر باسمه (والمدير في أي حتة)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('venue-photos', 'venue-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "venue photos read" on storage.objects;
create policy "venue photos read" on storage.objects for select using (bucket_id = 'venue-photos');
drop policy if exists "venue photos manager upload" on storage.objects;
drop policy if exists "venue photos upload" on storage.objects;
create policy "venue photos upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'venue-photos'
    and (public.is_manager() or (storage.foldername(name))[1] = auth.uid()::text));
drop policy if exists "venue photos manager delete" on storage.objects;
drop policy if exists "venue photos delete" on storage.objects;
create policy "venue photos delete" on storage.objects for delete to authenticated
  using (bucket_id = 'venue-photos'
    and (public.is_manager() or (storage.foldername(name))[1] = auth.uid()::text));


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 10) SEASONS & CHIPS                                            ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- الموسم: المدير بيحدد البداية ونص الموسم والنهاية.
create table if not exists public.seasons (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  starts_at  timestamptz not null,
  mid_at     timestamptz not null,
  ends_at    timestamptz not null,
  created_at timestamptz not null default now(),
  check (starts_at < mid_at and mid_at < ends_at)
);
alter table public.seasons enable row level security;
drop policy if exists "seasons read" on public.seasons;
create policy "seasons read" on public.seasons for select to authenticated using (true);
drop policy if exists "seasons manager write" on public.seasons;
create policy "seasons manager write" on public.seasons for all to authenticated
  using (public.is_manager()) with check (public.is_manager());

create or replace function public.fn_season_at(ts timestamptz)
returns public.seasons language sql stable as $$
  select * from public.seasons where ts >= starts_at and ts < ends_at order by starts_at desc limit 1;
$$;

-- الكروت: triple (كابتن ×٣) · bench_boost (الاحتياطي يتحسب) · wildcard (تعدّل بعد القفل لحد البداية)
--          double (نقط التشكيلة كلها ×٢)
-- الحدود: triple/bench_boost/wildcard → مرتين في كل نص موسم · double → مرتين في الموسم كله.
-- كارت واحد بس في الجولة (week_cutoff = نهاية الجولة) ومبيتلغيش. match_id للكروت القديمة بس.
create table if not exists public.chip_uses (
  user_id     uuid references public.profiles(id) on delete cascade,
  match_id    uuid references public.matches(id) on delete cascade,
  chip        text not null check (chip in ('triple', 'bench_boost', 'wildcard', 'double')),
  season_id   uuid not null references public.seasons(id) on delete cascade,
  half        int not null check (half in (1, 2)),
  week_cutoff timestamptz not null,
  created_at  timestamptz not null default now(),
  primary key (user_id, match_id),
  unique (user_id, week_cutoff)
);
do $$ begin
  alter table public.chip_uses drop constraint chip_uses_pkey;
exception when undefined_object then null; end $$;
alter table public.chip_uses alter column match_id drop not null;
alter table public.chip_uses enable row level security;
drop policy if exists "chips read" on public.chip_uses;
create policy "chips read" on public.chip_uses for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
-- مفيش كتابة مباشرة (ولا حذف = مبيتلغيش): التفعيل بدالة activate_chip بس.

create or replace function public.fn_chip_limit(p_chip text)
returns int language sql immutable as $$ select 2; $$;

create or replace function public.fn_chip_name(p_chip text)
returns text language sql immutable as $$
  select case p_chip when 'triple' then 'كابتن ×٣' when 'bench_boost' then 'الاحتياطي يتحسب'
    when 'wildcard' then 'الوايلد كارد' when 'double' then 'الدبل ×٢' else p_chip end;
$$;

-- حالة الكروت لجولة (للشاشة): المستخدم، الحد، مفعّل فيها، وسبب المنع لو ممنوع.
drop function if exists public.chip_status(uuid);
create or replace function public.chip_status(p_round timestamptz)
returns table(chip text, used int, lim int, active boolean, blocked text)
language plpgsql stable security definer set search_path = public as $$
declare st timestamptz := p_round - interval '7 days'; s public.seasons; h int; here text; has_picks boolean;
begin
  s := public.fn_season_at(st);
  select c.chip into here from public.chip_uses c where c.user_id = auth.uid() and c.week_cutoff = p_round;
  has_picks := exists(select 1 from public.round_picks p where p.user_id = auth.uid() and p.round_end = p_round);
  if s.id is not null then
    h := case when st < s.mid_at then 1 else 2 end;
  end if;

  return query
  select k.chip,
    case when s.id is null then 0
         when k.chip = 'double' then (select count(*)::int from public.chip_uses c
              where c.user_id = auth.uid() and c.season_id = s.id and c.chip = 'double')
         else (select count(*)::int from public.chip_uses c
              where c.user_id = auth.uid() and c.season_id = s.id and c.chip = k.chip and c.half = h) end,
    public.fn_chip_limit(k.chip),
    coalesce(here = k.chip, false),
    case
      when here is not null then (case when here = k.chip then null else 'فعّلت ' || public.fn_chip_name(here) || ' في الجولة دي' end)
      when s.id is null then 'مفيش موسم شغّال'
      when k.chip = 'wildcard' and now() >= st then 'الجولة بدأت'
      when k.chip <> 'wildcard' and now() >= public.fn_round_deadline(p_round) then 'التشكيلة اتقفلت'
      when not has_picks then 'احفظ تشكيلتك الأول'
      else null end
  from (values ('triple'), ('bench_boost'), ('wildcard'), ('double')) as k(chip);
end $$;
grant execute on function public.chip_status(timestamptz) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 11) CHALLENGE — توقّع النتيجة                                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.predictions (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  score_a    int not null check (score_a between 0 and 99),
  score_b    int not null check (score_b between 0 and 99),
  created_at timestamptz not null default now(),
  primary key (user_id, match_id)
);
create index if not exists predictions_match on public.predictions(match_id);
alter table public.predictions enable row level security;

-- توقعات الناس تبان بعد ما الماتش يبدأ بس
drop policy if exists "predictions read" on public.predictions;
create policy "predictions read" on public.predictions for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.matches m where m.id = match_id and m.date_time <= now())
);
drop policy if exists "predictions own write" on public.predictions;
create policy "predictions own write" on public.predictions for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and exists (
    select 1 from public.matches m where m.id = match_id and m.is_challenge
      and m.organizer_id is distinct from auth.uid()
      and m.status = 'upcoming' and now() < m.date_time - interval '1 hour'));

-- (مدير) يعلن ماتش تحدّي الجولة
create or replace function public.set_challenge(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  select * into m from public.matches where id = p_match;
  if not found or m.status <> 'upcoming' then raise exception 'اختار ماتش لسه ملعبش'; end if;
  update public.matches set is_challenge = true where id = p_match;
  insert into public.notifications (title, body, kind, match_id)
  values ('🎯 تحدّي الجولة', 'توقّع نتيجة ' || m.teams[1] || ' ضد ' || m.teams[2] || ' صح واكسب +٥ نقط', 'challenge', p_match);
end $$;
grant execute on function public.set_challenge(uuid) to authenticated;

-- ملخص التوقعات بعد الماتش: كام واحد توقّع، وكام جابها صح
create or replace function public.challenge_summary(p_match uuid)
returns table(total bigint, correct bigint)
language sql stable security definer set search_path = public as $$
  select count(*), count(*) filter (where p.score_a = m.score_a and p.score_b = m.score_b)
  from public.predictions p join public.matches m on m.id = p.match_id where p.match_id = p_match;
$$;
grant execute on function public.challenge_summary(uuid) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 12) FOLLOWS — متابعة ماتش لايف                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.match_follows (
  user_id    uuid references public.profiles(id) on delete cascade,
  match_id   uuid references public.matches(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, match_id)
);
create index if not exists follows_match on public.match_follows(match_id);
alter table public.match_follows enable row level security;
drop policy if exists "follows own" on public.match_follows;
create policy "follows own" on public.match_follows for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- الحد: ٣ ماتشات بس في اليوم (بيوم الماتش بتوقيت القاهرة)، ومش ماتش خلص.
create or replace function public.trg_follow_limit()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; n int;
begin
  select * into m from public.matches where id = new.match_id;
  if not found then raise exception 'الماتش مش موجود'; end if;
  if m.status = 'finished' then raise exception 'الماتش ده خلص'; end if;
  select count(*) into n from public.match_follows f join public.matches x on x.id = f.match_id
  where f.user_id = new.user_id
    and (x.date_time at time zone 'Africa/Cairo')::date = (m.date_time at time zone 'Africa/Cairo')::date;
  if n >= 3 then raise exception 'آخرك ٣ ماتشات تتابعها في اليوم'; end if;
  return new;
end $$;
drop trigger if exists follow_limit on public.match_follows;
create trigger follow_limit before insert on public.match_follows
for each row execute function public.trg_follow_limit();

-- قراءة الإشعارات: الكل + الموجّهة ليك + أحداث الماتشات اللي بتتابعها
drop policy if exists "notifications read" on public.notifications;
create policy "notifications read" on public.notifications for select to authenticated using (
  audience = 'all'
  or (audience = 'user' and user_id = auth.uid())
  or (audience = 'zone' and zone_id = (select p.zone_id from public.profiles p where p.id = auth.uid()))
  or (audience = 'match' and exists (select 1 from public.match_follows f
        where f.match_id = notifications.match_id and f.user_id = auth.uid()))
);

-- كل حدث بيتسجّل → إشعار لمتابعين الماتش
create or replace function public.trg_event_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare m public.matches; pn text;
begin
  select * into m from public.matches where id = new.match_id;
  select name into pn from public.players where id = new.player_id;
  insert into public.notifications (title, body, kind, match_id, audience)
  values (public.fn_event_label(new.type) || ' — ' || coalesce(pn, ''),
          m.teams[1] || ' ضد ' || m.teams[2] || coalesce(' · الدقيقة ' || new.minute, ''),
          'event', new.match_id, 'match');
  return new;
end $$;
drop trigger if exists event_notify on public.events;
create trigger event_notify after insert on public.events
for each row execute function public.trg_event_notify();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 13) RATINGS — تقييم الجمهور + رجل المباراة                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- وقت انتهاء الماتش بيتسجّل لوحده (التقييم مفتوح ٢٤ ساعة بعده)
create or replace function public.trg_match_finished_at()
returns trigger language plpgsql as $$
begin
  if new.status = 'finished' and old.status is distinct from 'finished' then
    new.finished_at := now();
  elsif new.status <> 'finished' then
    new.finished_at := null;
  end if;
  return new;
end $$;
drop trigger if exists match_finished_at on public.matches;
create trigger match_finished_at before update on public.matches
for each row execute function public.trg_match_finished_at();

create table if not exists public.player_ratings (
  match_id   uuid references public.matches(id) on delete cascade,
  player_id  uuid references public.players(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  rating     int not null check (rating between 1 and 10),
  created_at timestamptz not null default now(),
  primary key (match_id, player_id, user_id)
);
alter table public.player_ratings enable row level security;

create or replace function public.fn_rating_open(p_match uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.matches m where m.id = p_match and m.status = 'finished'
    and m.finished_at is not null and m.finished_at > now() - interval '24 hours' and not m.motm_done);
$$;

drop policy if exists "ratings read own" on public.player_ratings;
create policy "ratings read own" on public.player_ratings for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "ratings own write" on public.player_ratings;
create policy "ratings own write" on public.player_ratings for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and public.fn_rating_open(match_id)
    and exists (select 1 from public.lineups l where l.match_id = player_ratings.match_id
                and l.player_id = player_ratings.player_id));

-- متوسط تقييم كل لاعب في الماتش + عدد الأصوات + تقييمك
create or replace function public.match_rating_summary(p_match uuid)
returns table(player_id uuid, avg numeric, votes bigint, mine int)
language sql stable security definer set search_path = public as $$
  select l.player_id,
    round(avg(r.rating)::numeric, 1),
    count(r.user_id),
    max(r.rating) filter (where r.user_id = auth.uid())
  from public.lineups l
  left join public.player_ratings r on r.match_id = l.match_id and r.player_id = l.player_id
  where l.match_id = p_match
  group by l.player_id;
$$;
grant execute on function public.match_rating_summary(uuid) to authenticated;

-- بعد ٢٤ ساعة: أعلى تقييم = رجل المباراة → حدث motm (+٣) + إشعار
create or replace function public.fn_close_ratings()
returns void language plpgsql security definer set search_path = public as $$
declare r record; w uuid; wn text;
begin
  for r in select id, teams from public.matches
           where status = 'finished' and not motm_done and finished_at is not null
             and finished_at <= now() - interval '24 hours' loop
    w := null;
    select pr.player_id into w from public.player_ratings pr where pr.match_id = r.id
      group by pr.player_id order by avg(pr.rating) desc, count(*) desc limit 1;
    update public.matches set motm_done = true, motm_player_id = w where id = r.id;
    if w is not null then
      select name into wn from public.players where id = w;
      insert into public.events (match_id, player_id, type) values (r.id, w, 'motm');
      perform public.fn_notify_match(r.id, '⭐ رجل المباراة: ' || wn,
        r.teams[1] || ' ضد ' || r.teams[2] || ' · +٣ نقط بتصويت الجمهور', 'match');
    end if;
  end loop;
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 14) PLAYER CLAIMS — اللاعب يوثّق بروفايله                      ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.player_claims (
  id          uuid primary key default gen_random_uuid(),
  player_id   uuid not null references public.players(id) on delete cascade,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  status      text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  note        text check (note is null or length(note) <= 300),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);
create unique index if not exists claims_one_pending on public.player_claims(user_id) where status = 'pending';
alter table public.player_claims enable row level security;
drop policy if exists "claims read" on public.player_claims;
create policy "claims read" on public.player_claims for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "claims request" on public.player_claims;
create policy "claims request" on public.player_claims for insert to authenticated with check (
  user_id = auth.uid() and status = 'pending'
  and not exists (select 1 from public.players p where p.id = player_id and p.user_id is not null)
  and not exists (select 1 from public.players p where p.user_id = auth.uid())
);

-- طلب جديد → إشعار لكل المديرين
create or replace function public.trg_claim_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare pn text; un text;
begin
  select name into pn from public.players where id = new.player_id;
  select name into un from public.profiles where id = new.user_id;
  insert into public.notifications (title, body, kind, user_id)
  select '🪪 طلب توثيق لاعب', coalesce(un, 'يوزر') || ' بيقول إنه ' || coalesce(pn, ''), 'status', p.id
  from public.profiles p where p.role = 'manager';
  return new;
end $$;
drop trigger if exists claim_notify on public.player_claims;
create trigger claim_notify after insert on public.player_claims
for each row execute function public.trg_claim_notify();

-- (مدير) موافقة/رفض
create or replace function public.review_claim(p_claim uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare c public.player_claims; pn text;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  select * into c from public.player_claims where id = p_claim;
  if not found or c.status <> 'pending' then raise exception 'الطلب مش موجود أو اتراجع'; end if;
  select name into pn from public.players where id = c.player_id;
  if p_approve then
    if exists (select 1 from public.players where id = c.player_id and user_id is not null) then
      raise exception 'اللاعب ده موثّق لحد تاني';
    end if;
    update public.players set user_id = c.user_id where id = c.player_id;
    update public.player_claims set status = 'approved', reviewed_at = now() where id = c.id;
    update public.player_claims set status = 'rejected', reviewed_at = now()
      where player_id = c.player_id and status = 'pending' and id <> c.id;
    insert into public.notifications (title, body, kind, user_id)
    values ('✓ اتوثّق بروفايلك', 'بقيت ' || pn || ' رسميًا — افتح "أنا كلاعب" وشوف مين اختارك', 'status', c.user_id);
  else
    update public.player_claims set status = 'rejected', reviewed_at = now() where id = c.id;
    insert into public.notifications (title, body, kind, user_id)
    values ('طلب التوثيق اترفض', 'المدير مقدرش يأكّد إنك ' || pn, 'status', c.user_id);
  end if;
end $$;
grant execute on function public.review_claim(uuid, boolean) to authenticated;

-- (مدير) فك التوثيق
create or replace function public.unlink_player(p_player uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  update public.players set user_id = null where id = p_player;
end $$;
grant execute on function public.unlink_player(uuid) to authenticated;

-- الطلبات المعلّقة بالأسماء (للمدير)
create or replace function public.pending_claims()
returns table(id uuid, player_id uuid, player_name text, team text, user_id uuid, user_name text,
              phone text, note text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  return query select c.id, c.player_id, pl.name, pl.team, c.user_id, pr.name, pr.phone, c.note, c.created_at
    from public.player_claims c join public.players pl on pl.id = c.player_id
    join public.profiles pr on pr.id = c.user_id
    where c.status = 'pending' order by c.created_at;
end $$;
grant execute on function public.pending_claims() to authenticated;


-- "أنا كلاعب": كام واحد اختارك وخلّاك كابتن في الجولة + امتلاكك وترتيبك في مركزك
-- + النقط اللي جبتها لليوزرز من أول الموسم (الأساسي بس، والكابتن ×٢)
create or replace function public.player_fan_stats(p_player uuid, p_from timestamptz, p_to timestamptz)
returns table(owners bigint, captains bigint, managers bigint, ownership numeric,
              pos_rank bigint, pos_total bigint, points_for_users bigint)
language sql stable security definer set search_path = public as $$
  with w as (select * from public.player_window_stats(p_from, p_to)),
  me as (select * from w where w.id = p_player),
  pos as (select w.id, w.ownership from w join public.players pl on pl.id = w.id
          where pl.position = (select position from public.players where id = p_player)),
  since as (select coalesce((public.fn_season_at(now())).starts_at, '-infinity'::timestamptz) as t)
  select me.owners,
    (select count(distinct rp.user_id) from public.round_picks rp
     where rp.player_id = p_player and rp.is_captain and rp.round_end > p_from and rp.round_end <= p_to),
    me.managers, me.ownership,
    (select count(*) + 1 from pos where pos.ownership > me.ownership),
    (select count(*) from pos),
    (select coalesce(sum(x.base * case when rp.is_captain then 2 else 1 end), 0)
     from public.round_picks rp
     cross join lateral (
       select coalesce(sum(public.fn_event_points(e.type, pl.position)), 0) as base
       from public.events e join public.players pl on pl.id = e.player_id
       join public.matches m on m.id = e.match_id
       where e.player_id = rp.player_id and m.review_status <> 'void'
         and m.date_time > rp.round_end - interval '7 days' and m.date_time <= rp.round_end) x
     where rp.player_id = p_player and rp.status = 'starting'
       and rp.round_end > (select t from since))::bigint
  from me;
$$;
grant execute on function public.player_fan_stats(uuid, timestamptz, timestamptz) to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 15) SCORING v2 — النقاط بالكروت والبونص + حفظ التشكيلة          ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- نقط كل يوزر في كل ماتش (مخزّنة عشان الترتيب والإنجازات يبقوا سريعين)
create table if not exists public.user_match_points (
  user_id  uuid references public.profiles(id) on delete cascade,
  match_id uuid references public.matches(id) on delete cascade,
  points   int not null default 0,
  primary key (user_id, match_id)
);
create index if not exists ump_match on public.user_match_points(match_id);
alter table public.user_match_points enable row level security;
drop policy if exists "ump read" on public.user_match_points;
create policy "ump read" on public.user_match_points for select to authenticated using (true);

-- نقط تشكيلة يوزر في ماتش (نفس MatchPoints في Dart بالظبط):
--   الأساسيين بس (إلا مع bench_boost الكل) · الكابتن ×٢ لو لعب، ولو ملعبش النائب ×٢
--   triple → المضاعف ×٣ · double → المجموع كله ×٢
create or replace function public.fn_user_match_points(p_user uuid, p_match uuid)
returns int language sql stable security definer set search_path = public as $$
  with chip as (
    select coalesce((select c.chip from public.chip_uses c
                     where c.user_id = p_user and c.match_id = p_match), '') as c
  ), pts as (
    select pk.status, pk.is_captain, pk.is_vice,
      coalesce((select sum(public.fn_event_points(e.type, pl.position)) from public.events e
                where e.player_id = pk.player_id and e.match_id = p_match), 0) as base,
      exists (select 1 from public.events e where e.player_id = pk.player_id and e.match_id = p_match) as played
    from public.picks pk join public.players pl on pl.id = pk.player_id
    where pk.user_id = p_user and pk.match_id = p_match
  ), cap as (
    select coalesce(bool_or(is_captain and played), false) as cap_played from pts
  )
  select (coalesce(sum(
      pts.base * case
        when (pts.is_captain and cap.cap_played) or (pts.is_vice and not cap.cap_played)
          then case when (select c from chip) = 'triple' then 3 else 2 end
        else 1 end
    ) filter (where pts.status = 'starting' or (select c from chip) = 'bench_boost'), 0)
    * case when (select c from chip) = 'double' then 2 else 1 end)::int
  from pts cross join cap;
$$;

-- بونص التوقعات الصح (+٥ لكل واحدة)
create or replace function public.fn_user_bonus(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select (5 * count(*))::int from public.predictions pr join public.matches m on m.id = pr.match_id
  where pr.user_id = p_user and m.is_challenge and m.status = 'finished' and m.review_status = 'approved'
    and pr.score_a = m.score_a and pr.score_b = m.score_b;
$$;

-- نقط تشكيلة يوزر في جولة (نفس LineupPoints في Dart بالظبط):
--   نقط كل لاعب = مجموع أحداثه في كل ماتشات الجولة (p_final: المعتمدة بس)
--   الأساسيين بس (إلا مع bench_boost الكل) · الكابتن ×٢ لو لعب في الجولة، ولو ملعبش البديل ×٢
--   triple → المضاعف ×٣ · double → المجموع كله ×٢
create or replace function public.fn_user_round_points(p_user uuid, p_round timestamptz, p_final boolean)
returns int language sql stable security definer set search_path = public as $$
  with chip as (
    select coalesce((select c.chip from public.chip_uses c
                     where c.user_id = p_user and c.week_cutoff = p_round), '') as c
  ), ms as (
    select m.id from public.matches m
    where m.date_time > p_round - interval '7 days' and m.date_time <= p_round
      and m.review_status <> 'void' and (not p_final or m.review_status = 'approved')
  ), pts as (
    select rp.status, rp.is_captain, rp.is_vice,
      coalesce(sum(public.fn_event_points(e.type, pl.position)), 0) as base,
      count(e.id) > 0 as played
    from public.round_picks rp
    join public.players pl on pl.id = rp.player_id
    left join public.events e on e.player_id = rp.player_id and e.match_id in (select id from ms)
    where rp.user_id = p_user and rp.round_end = p_round
    group by rp.player_id, rp.status, rp.is_captain, rp.is_vice
  ), cap as (
    select coalesce(bool_or(is_captain and played), false) as cap_played from pts
  )
  select (coalesce(sum(
      pts.base * case
        when (pts.is_captain and cap.cap_played) or (pts.is_vice and not cap.cap_played)
          then case when (select c from chip) = 'triple' then 3 else 2 end
        else 1 end
    ) filter (where pts.status = 'starting' or (select c from chip) = 'bench_boost'), 0)
    * case when (select c from chip) = 'double' then 2 else 1 end)::int
  from pts cross join cap;
$$;

-- إجمالي نقاط اليوزر = المعتمد من الجولات + ماتشات النظام القديم المعتمدة + البونص
create or replace function public.fn_user_points(p_user uuid)
returns int language sql stable security definer set search_path = public as $$
  select (coalesce((select sum(r.final_points) from public.user_round_points r where r.user_id = p_user), 0)
          + coalesce((select sum(u.points) from public.user_match_points u
                      join public.matches m on m.id = u.match_id
                      where u.user_id = p_user and m.review_status = 'approved'), 0)
          + public.fn_user_bonus(p_user))::int;
$$;

create or replace function public.fn_recalc_user_round(p_user uuid, p_round timestamptz)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.round_picks where user_id = p_user and round_end = p_round) then
    insert into public.user_round_points (user_id, round_end, points, final_points)
    values (p_user, p_round, public.fn_user_round_points(p_user, p_round, false),
            public.fn_user_round_points(p_user, p_round, true))
    on conflict (user_id, round_end) do update
      set points = excluded.points, final_points = excluded.final_points;
  else
    delete from public.user_round_points where user_id = p_user and round_end = p_round;
  end if;
  update public.profiles set total_points = public.fn_user_points(p_user), badges_dirty = true
  where id = p_user;
end $$;

-- نقط كل اللي اختاروا لاعيبة معيّنة في جولة (بعد حدث أو اعتماد ماتش)
create or replace function public.fn_recalc_round_players(p_round timestamptz, p_players uuid[])
returns void language plpgsql security definer set search_path = public as $$
declare users uuid[];
begin
  if p_round is null then return; end if;
  select array_agg(distinct user_id) into users
  from public.round_picks where round_end = p_round and player_id = any(p_players);
  if users is null then return; end if;
  insert into public.user_round_points (user_id, round_end, points, final_points)
  select x.u, p_round, public.fn_user_round_points(x.u, p_round, false), public.fn_user_round_points(x.u, p_round, true)
  from unnest(users) as x(u)
  on conflict (user_id, round_end) do update
    set points = excluded.points, final_points = excluded.final_points;
  update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
  where id = any(users);
end $$;

create or replace function public.fn_recalc_user_match(p_user uuid, p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from public.picks where user_id = p_user and match_id = p_match) then
    insert into public.user_match_points (user_id, match_id, points)
    values (p_user, p_match, public.fn_user_match_points(p_user, p_match))
    on conflict (user_id, match_id) do update set points = excluded.points;
  else
    delete from public.user_match_points where user_id = p_user and match_id = p_match;
  end if;
  update public.profiles set total_points = public.fn_user_points(p_user), badges_dirty = true
  where id = p_user;
end $$;

create or replace function public.fn_recalc_match(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_match_points (user_id, match_id, points)
  select u.user_id, p_match, public.fn_user_match_points(u.user_id, p_match)
  from (select distinct user_id from public.picks where match_id = p_match) u
  on conflict (user_id, match_id) do update set points = excluded.points;
  delete from public.user_match_points
  where match_id = p_match and user_id not in (select user_id from public.picks where match_id = p_match);
  update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
  where id in (select distinct user_id from public.picks where match_id = p_match);
end $$;

-- إعادة حساب الكل (يدوي من SQL Editor)
create or replace function public.fn_recalc_users()
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.user_match_points (user_id, match_id, points)
  select u.user_id, u.match_id, public.fn_user_match_points(u.user_id, u.match_id)
  from (select distinct user_id, match_id from public.picks) u
  on conflict (user_id, match_id) do update set points = excluded.points;
  delete from public.user_match_points ump where not exists (
    select 1 from public.picks p where p.user_id = ump.user_id and p.match_id = ump.match_id);
  insert into public.user_round_points (user_id, round_end, points, final_points)
  select u.user_id, u.round_end, public.fn_user_round_points(u.user_id, u.round_end, false),
         public.fn_user_round_points(u.user_id, u.round_end, true)
  from (select distinct user_id, round_end from public.round_picks) u
  on conflict (user_id, round_end) do update
    set points = excluded.points, final_points = excluded.final_points;
  update public.profiles set total_points = public.fn_user_points(id) where id is not null;
end $$;

-- أي تغيير في الأحداث → إحصائيات اللاعب + نقط اللي اختاروه في الجولة (+ الماتش القديم لو ليه تشكيلات)
create or replace function public.trg_events_recalc()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.fn_recalc_player(old.player_id);
    perform public.fn_recalc_match(old.match_id);
    perform public.fn_recalc_round_players(
      public.fn_week_cutoff((select date_time from public.matches where id = old.match_id)), array[old.player_id]);
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.fn_recalc_player(new.player_id);
    if tg_op = 'INSERT' or new.match_id is distinct from old.match_id then
      perform public.fn_recalc_match(new.match_id);
    end if;
    perform public.fn_recalc_round_players(
      public.fn_week_cutoff((select date_time from public.matches where id = new.match_id)), array[new.player_id]);
  end if;
  return null;
end $$;
drop trigger if exists events_recalc on public.events;
create trigger events_recalc after insert or update or delete on public.events
for each row execute function public.trg_events_recalc();

-- الاعتماد اتغيّر (أو النتيجة اتعدّلت بعد الاعتماد) → إجمالي نقط اللي لعبوا/توقّعوا
-- + أول ما ماتش التحدّي يتعتمد: إشعار للي توقّعوا صح
create or replace function public.trg_match_result()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.review_status is distinct from old.review_status
     or (new.review_status = 'approved' and (new.score_a, new.score_b, new.is_challenge)
           is distinct from (old.score_a, old.score_b, old.is_challenge)) then
    update public.profiles set total_points = public.fn_user_points(id), badges_dirty = true
    where id in (select user_id from public.picks where match_id = new.id
                 union select user_id from public.predictions where match_id = new.id);
    -- تشكيلات الجولة: كل اللي اختاروا حد من لاعيبة الفريقين
    perform public.fn_recalc_round_players(public.fn_week_cutoff(new.date_time),
      array(select id from public.players where team = any(new.teams)));
    if new.is_challenge and new.review_status = 'approved' and old.review_status is distinct from 'approved' then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🎯 توقّعك صح! +٥', new.teams[1] || ' ' || new.score_a || ' - ' || new.score_b || ' ' || new.teams[2],
             'challenge', p.user_id, new.id
      from public.predictions p
      where p.match_id = new.id and p.score_a = new.score_a and p.score_b = new.score_b;
    end if;
  end if;
  return null;
end $$;
drop trigger if exists match_result on public.matches;
create trigger match_result after update on public.matches
for each row execute function public.trg_match_result();

-- حفظ تشكيلة الجولة (استبدال كامل في transaction واحدة) + التحقّق من القواعد في السيرفر:
-- ٧ لاعيبة من منطقتك: ٥ أساسي (حارس واحد) + ٢ احتياطي + كابتن + كابتن بديل (من الأساسيين).
-- مفتوحة لحد ديدلاين الجولة (السبت ١٢ الضهر)، أو بالوايلد كارد لحد ما الجولة تبدأ (٤ العصر).
drop function if exists public.save_picks(uuid, jsonb);
drop function if exists public.fn_can_edit_picks(uuid);
create or replace function public.save_round_picks(p_round timestamptz, p_picks jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); z int;
        n_start int; n_bench int; n_gk int; n_cap int; n_vice int; n_bad int; n_dup int; n_zone int; n_mine int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  if jsonb_typeof(p_picks) <> 'array' then raise exception 'بيانات غلط'; end if;
  if public.fn_week_cutoff(p_round) is distinct from p_round then raise exception 'جولة غلط'; end if;
  if p_round > public.fn_open_round() + interval '7 days' then raise exception 'الجولة دي لسه بعيدة'; end if;
  if not (now() < public.fn_round_deadline(p_round)
          or (now() < p_round - interval '7 days' and exists (select 1 from public.chip_uses c
                where c.user_id = u and c.week_cutoff = p_round and c.chip = 'wildcard'))) then
    raise exception 'التشكيلة اتقفلت — ديدلاين الجولة (السبت ١٢ الضهر) عدّى';
  end if;
  select zone_id into z from public.profiles where id = u;

  with sel as (
    select * from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean)
  ), j as (
    select s.player_id, s.status, coalesce(s.is_captain, false) as cap, coalesce(s.is_vice, false) as vic,
           pl.id as pid, pl.position, pl.zone_id, pl.team
    from sel s left join public.players pl on pl.id = s.player_id
  )
  select count(*) filter (where j.status = 'starting'),
         count(*) filter (where j.status = 'bench'),
         count(*) filter (where j.status = 'starting' and j.position = 'GK'),
         count(*) filter (where j.cap),
         count(*) filter (where j.vic),
         count(*) filter (where j.pid is null or j.status not in ('starting', 'bench')
                          or ((j.cap or j.vic) and j.status <> 'starting') or (j.cap and j.vic)),
         count(*) - count(distinct j.player_id),
         count(*) filter (where j.zone_id is not null and j.zone_id is distinct from z),
         count(*) filter (where exists (select 1 from public.teams t
                                        where lower(trim(t.name)) = lower(trim(j.team)) and t.owner_id = u))
  into n_start, n_bench, n_gk, n_cap, n_vice, n_bad, n_dup, n_zone, n_mine
  from j;

  if n_bad > 0 or n_dup > 0 then raise exception 'فيه لاعب غلط في التشكيلة — حدّث الصفحة'; end if;
  if n_zone > 0 then raise exception 'فيه لاعب مش من منطقتك'; end if;
  if n_mine > 0 then raise exception 'مينفعش تختار لاعيبة من فرقك انت كمنظّم'; end if;
  if n_start <> 5 then raise exception 'لازم ٥ أساسيين بالظبط'; end if;
  if n_bench <> 2 then raise exception 'لازم ٢ احتياطي'; end if;
  if n_gk <> 1 then raise exception 'لازم حارس واحد في الأساسيين'; end if;
  if n_cap <> 1 then raise exception 'اختار كابتن من الأساسيين'; end if;
  if n_vice <> 1 then raise exception 'اختار كابتن بديل من الأساسيين'; end if;

  delete from public.round_picks where user_id = u and round_end = p_round;
  insert into public.round_picks (user_id, round_end, player_id, status, is_captain, is_vice, saved_at)
  select u, p_round, x.player_id, x.status, coalesce(x.is_captain, false), coalesce(x.is_vice, false), now()
  from jsonb_to_recordset(p_picks) as x(player_id uuid, status text, is_captain boolean, is_vice boolean);
  perform public.fn_recalc_user_round(u, p_round);
end $$;
grant execute on function public.save_round_picks(timestamptz, jsonb) to authenticated;

-- تفعيل كارت على جولة (مبيتلغيش): قبل الديدلاين، والوايلد كارد لحد ما الجولة تبدأ
drop function if exists public.activate_chip(uuid, text);
create or replace function public.activate_chip(p_round timestamptz, p_chip text)
returns void language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); st timestamptz := p_round - interval '7 days'; s public.seasons; h int; used int;
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  if p_chip not in ('triple', 'bench_boost', 'wildcard', 'double') then raise exception 'كارت مش معروف'; end if;
  if public.fn_week_cutoff(p_round) is distinct from p_round then raise exception 'جولة غلط'; end if;
  perform pg_advisory_xact_lock(hashtext(u::text));
  if p_chip = 'wildcard' then
    if now() >= st then raise exception 'الجولة بدأت'; end if;
  elsif now() >= public.fn_round_deadline(p_round) then
    raise exception 'التشكيلة اتقفلت — الكارت لازم يتفعّل قبل الديدلاين';
  end if;
  if not exists (select 1 from public.round_picks where user_id = u and round_end = p_round) then
    raise exception 'احفظ تشكيلتك للجولة دي الأول';
  end if;
  s := public.fn_season_at(st);
  if s.id is null then raise exception 'مفيش موسم شغّال — المدير لازم يحدّد مواعيد الموسم'; end if;
  h := case when st < s.mid_at then 1 else 2 end;
  if exists (select 1 from public.chip_uses where user_id = u and week_cutoff = p_round) then
    raise exception 'استخدمت كارت في الجولة دي — كارت واحد بس في الجولة';
  end if;
  if p_chip = 'double' then
    select count(*) into used from public.chip_uses where user_id = u and season_id = s.id and chip = 'double';
    if used >= public.fn_chip_limit(p_chip) then raise exception 'الدبل خلص — مرتين بس في الموسم'; end if;
  else
    select count(*) into used from public.chip_uses
    where user_id = u and season_id = s.id and chip = p_chip and half = h;
    if used >= public.fn_chip_limit(p_chip) then
      raise exception '% خلص — مرتين بس في النص ده من الموسم', public.fn_chip_name(p_chip);
    end if;
  end if;
  insert into public.chip_uses (user_id, chip, season_id, half, week_cutoff)
  values (u, p_chip, s.id, h, p_round);
  perform public.fn_recalc_user_round(u, p_round);
end $$;
grant execute on function public.activate_chip(timestamptz, text) to authenticated;

select public.fn_recalc_users();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 16) LEAGUES — أي يوزر يعمل دوري                                 ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- الدوري يبان لأعضائه وصاحبه والمدير (والعام للكل) — الأكواد متتسرّبش.
drop policy if exists "leagues read" on public.leagues;
create policy "leagues read" on public.leagues for select to authenticated using (
  type in ('public', 'global') or owner_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.league_members lm where lm.league_id = leagues.id and lm.user_id = auth.uid())
);
drop policy if exists "leagues insert" on public.leagues;
create policy "leagues insert" on public.leagues for insert to authenticated with check (
  owner_id = auth.uid() and type <> 'global'
  and (public.is_manager() or (select count(*) from public.leagues l where l.owner_id = auth.uid()) < 10)
);
drop policy if exists "leagues manager delete" on public.leagues;
drop policy if exists "leagues delete" on public.leagues;
create policy "leagues delete" on public.leagues for delete to authenticated
  using (owner_id = auth.uid() or public.is_manager());
drop policy if exists "leagues update" on public.leagues;
create policy "leagues update" on public.leagues for update to authenticated
  using (owner_id = auth.uid() or public.is_manager())
  with check ((owner_id = auth.uid() and type <> 'global') or public.is_manager());
-- الخروج من دوري: العضو نفسه، أو صاحب الدوري يطرده، أو المدير
create policy "members delete" on public.league_members for delete to authenticated using (
  auth.uid() = user_id or public.is_manager()
  or exists (select 1 from public.leagues l where l.id = league_id and l.owner_id = auth.uid())
);

-- الانضمام بالكود
create or replace function public.join_league(p_code text)
returns uuid language plpgsql security definer set search_path = public as $$
declare lid uuid;
begin
  if auth.uid() is null then raise exception 'سجّل دخولك الأول'; end if;
  select id into lid from public.leagues where invite_code = upper(trim(p_code));
  if lid is null then raise exception 'كود غير صحيح'; end if;
  if (select count(*) from public.league_members where league_id = lid) >= 500 then
    raise exception 'الدوري ده مليان';
  end if;
  insert into public.league_members (league_id, user_id) values (lid, auth.uid())
  on conflict do nothing;
  update public.profiles set badges_dirty = true
  where id = (select owner_id from public.leagues where id = lid);
  return lid;
end $$;
grant execute on function public.join_league(text) to authenticated;

-- دورياتي في طلب واحد: العام + اللي أنا عضو فيها، بعدد الأعضاء وترتيبي في كل واحد
create or replace function public.my_leagues()
returns table(id uuid, name text, type text, invite_code text, owner_id uuid, member_count bigint, my_rank bigint)
language sql stable security definer set search_path = public as $$
  with me as (select * from public.profiles where id = auth.uid()),
  mine as (
    select l.id, l.name, l.type, l.invite_code, l.owner_id from public.leagues l where l.type = 'global'
    union
    select l.id, l.name, l.type, l.invite_code, l.owner_id from public.leagues l
    join public.league_members m on m.league_id = l.id
    where m.user_id = auth.uid() and l.type <> 'global'
  )
  select mine.id, mine.name, mine.type, mine.invite_code, mine.owner_id,
    case when mine.type = 'global' then (select count(*) from public.profiles)
         else (select count(*) from public.league_members m where m.league_id = mine.id) end,
    1 + (select count(*) from public.profiles p, me
         where (mine.type = 'global'
                or p.id in (select m.user_id from public.league_members m where m.league_id = mine.id))
           and (p.total_points, p.low_picks, -p.avg_own) > (me.total_points, me.low_picks, -me.avg_own))
  from mine
  order by (mine.type = 'global') desc, mine.name;
$$;
grant execute on function public.my_leagues() to authenticated;

-- (مدير) كل الدوريات بأصحابها وعدد الأعضاء
create or replace function public.admin_leagues()
returns table(id uuid, name text, type text, invite_code text, owner_id uuid, owner_name text,
              members bigint, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  return query select l.id, l.name, l.type, l.invite_code, l.owner_id, p.name,
    (select count(*) from public.league_members m where m.league_id = l.id), l.created_at
    from public.leagues l left join public.profiles p on p.id = l.owner_id
    order by l.created_at desc;
end $$;
grant execute on function public.admin_leagues() to authenticated;


-- ── الدوري العام: فيه كل اليوزرز أوتوماتيك (المدير بيعمله — واحد بس) ──
create unique index if not exists leagues_one_global on public.leagues(type) where type = 'global';

create or replace function public.create_global_league(p_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare lid uuid;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  if exists (select 1 from public.leagues where type = 'global') then raise exception 'الدوري العام موجود بالفعل'; end if;
  insert into public.leagues (name, type, owner_id)
  values (coalesce(nullif(trim(p_name), ''), 'دوري الخماسي العام'), 'global', auth.uid())
  returning id into lid;
  insert into public.notifications (title, body, kind)
  values ('🏆 الدوري العام بدأ', 'كل اليوزرز فيه أوتوماتيك — شوف ترتيبك في تاب الدوريات', 'match');
  return lid;
end $$;
grant execute on function public.create_global_league(text) to authenticated;

-- كسر التعادل: كام لاعب أساسي اخترته وامتلاكه في منطقتك في الجولة كان أقل من ٢٥٪ (الأكتر فوق)،
-- ولو لسه متعادلين: متوسط امتلاك اختياراتك الأقل فوق. (الجولات اللي ديدلاينها عدّى بس)
create or replace function public.fn_user_tiebreak()
returns table(user_id uuid, low_picks bigint, avg_own numeric)
language sql stable security definer set search_path = public as $$
  with rp as (
    select rp.user_id, rp.round_end, rp.player_id, rp.status, pr.zone_id
    from public.round_picks rp join public.profiles pr on pr.id = rp.user_id
    where rp.round_end - interval '7 days 4 hours' <= now()
  ), tot as (
    select rp.round_end, rp.zone_id, count(distinct rp.user_id)::numeric as n from rp group by rp.round_end, rp.zone_id
  ), own as (
    select rp.round_end, rp.zone_id, rp.player_id, count(*)::numeric as n from rp
    group by rp.round_end, rp.zone_id, rp.player_id
  ), mine as (
    select rp.user_id, own.n * 100 / tot.n as pct
    from rp
    join tot on tot.round_end = rp.round_end and tot.zone_id is not distinct from rp.zone_id
    join own on own.round_end = rp.round_end and own.zone_id is not distinct from rp.zone_id
            and own.player_id = rp.player_id
    where rp.status = 'starting'
  )
  select mine.user_id, count(*) filter (where mine.pct < 25), round(avg(mine.pct), 1)
  from mine group by mine.user_id;
$$;

-- بيتنادي من fn_tick: أول ما جولة تبدأ، كسر التعادل يتحدّث لليوزرز اللي لعبوها (مرة واحدة)
create or replace function public.fn_update_tiebreak()
returns void language plpgsql security definer set search_path = public as $$
declare r timestamptz := public.fn_week_cutoff(now());
begin
  insert into public.app_jobs (key) values ('tiebreak:' || to_char(r at time zone 'UTC', 'YYYYMMDDHH24'))
  on conflict do nothing;
  if not found then return; end if;
  update public.profiles p set low_picks = t.low_picks, avg_own = t.avg_own
  from public.fn_user_tiebreak() t
  where p.id = t.user_id
    and p.id in (select distinct rp.user_id from public.round_picks rp where rp.round_end = r);
end $$;

-- ترتيب دوري: النقط ثم كسر التعادل (المتعادلين بالظبط لهم نفس المركز). العام = كل اليوزرز.
drop function if exists public.league_standings(uuid);
create or replace function public.league_standings(p_league uuid)
returns table(rank bigint, user_id uuid, name text, photo_url text, points int, low_picks int)
language plpgsql stable security definer set search_path = public as $$
declare l public.leagues;
begin
  select * into l from public.leagues where id = p_league;
  if not found then return; end if;
  if not (l.type in ('public', 'global') or l.owner_id = auth.uid() or public.is_manager()
          or exists (select 1 from public.league_members m where m.league_id = l.id and m.user_id = auth.uid())) then
    raise exception 'مش عضو في الدوري ده';
  end if;
  return query
  select rank() over (order by p.total_points desc, p.low_picks desc, p.avg_own asc),
         p.id, p.name, p.photo_url, p.total_points, p.low_picks
  from public.profiles p
  where l.type = 'global'
     or p.id in (select m.user_id from public.league_members m where m.league_id = l.id)
  order by p.total_points desc, p.low_picks desc, p.avg_own asc, p.created_at
  limit 500;
end $$;
grant execute on function public.league_standings(uuid) to authenticated;

-- ترتيبي العام = كام واحد أحسن مني + ١
create or replace function public.my_global_rank()
returns bigint language sql stable security definer set search_path = public as $$
  select 1 + count(*) from public.profiles p, public.profiles me
  where me.id = auth.uid()
    and (p.total_points, p.low_picks, -p.avg_own) > (me.total_points, me.low_picks, -me.avg_own);
$$;
grant execute on function public.my_global_rank() to authenticated;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 17) AWARDS & TEAM OF THE WEEK                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

-- الفايز في تصويت = أكتر أصوات (التعادل: الأقدم)
create or replace function public.fn_poll_winner(p_poll uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select o.id from public.poll_options o left join public.poll_votes v on v.option_id = o.id
  where o.poll_id = p_poll group by o.id
  having count(v.user_id) > 0
  order by count(v.user_id) desc, min(o.id::text) limit 1;
$$;

-- (مدير) هدف/تصدّي الموسم: المرشّحين = كل اللي كسبوا هدف/تصدّي الجولة في الموسم الحالي
create or replace function public.create_season_award(p_kind text)
returns uuid language plpgsql security definer set search_path = public as $$
declare s public.seasons; pid uuid; n int;
begin
  if not public.is_manager() then raise exception 'للمدير بس'; end if;
  if p_kind not in ('goal', 'save') then raise exception 'نوع غلط'; end if;
  s := public.fn_season_at(now());
  if s.id is null then
    select * into s from public.seasons order by ends_at desc limit 1;
  end if;
  if s.id is null then raise exception 'مفيش موسم متسجّل'; end if;
  update public.polls set active = false where kind = p_kind || '_season' and active;
  insert into public.polls (kind, question, active)
  values (p_kind || '_season', case when p_kind = 'goal' then 'هدف الموسم 🏆' else 'تصدّي الموسم 🏆' end, true)
  returning id into pid;
  insert into public.poll_options (poll_id, label, player_id, video_url, match_id)
  select pid, o.label, o.player_id, o.video_url, o.match_id
  from public.polls p join public.poll_options o on o.id = public.fn_poll_winner(p.id)
  where p.kind = p_kind || '_week' and not p.active
    and p.created_at >= s.starts_at and p.created_at < s.ends_at;
  get diagnostics n = row_count;
  if n < 2 then raise exception 'محتاج فايزين اتنين على الأقل من جولات الموسم'; end if;
  insert into public.notifications (title, body, kind)
  values (case when p_kind = 'goal' then '🏆 تصويت هدف الموسم' else '🏆 تصويت تصدّي الموسم' end,
          'اتفرّج على أحلى ' || n || ' واختار الأحسن', 'vote');
  return pid;
end $$;
grant execute on function public.create_season_award(text) to authenticated;

-- قفل التصويتات اللي عدّى ميعادها + إعلان الفايز
create or replace function public.fn_close_polls()
returns void language plpgsql security definer set search_path = public as $$
declare r record; w text;
begin
  for r in select id, kind, question, zone_id from public.polls
           where active and closes_at is not null and closes_at <= now() loop
    update public.polls set active = false where id = r.id;
    select label into w from public.poll_options where id = public.fn_poll_winner(r.id);
    insert into public.notifications (title, body, kind, audience, zone_id)
    values (case when r.kind = 'totw_tie' then '⚖️ اتحسم التعادل' else '🏆 ' || r.question end,
            coalesce('الفايز: ' || w, 'التصويت خلص'), 'vote',
            case when r.zone_id is null then 'all' else 'zone' end, r.zone_id);
  end loop;
end $$;

-- تعادل على آخر مكان في تشكيلة الجولة (أعلى ٥) → تصويت لحد نص الليل — لكل منطقة لوحدها
create or replace function public.fn_totw_tie_zone(p_cutoff timestamptz, p_zone int)
returns void language plpgsql security definer set search_path = public as $$
declare ids uuid[]; names text[]; ps bigint[]; above int; slots int; pid uuid;
begin
  if exists (select 1 from public.polls where kind = 'totw_tie' and window_end = p_cutoff
             and zone_id is not distinct from p_zone) then return; end if;
  select array_agg(t.id order by t.points desc, t.name), array_agg(t.name order by t.points desc, t.name),
         array_agg(t.points order by t.points desc, t.name)
  into ids, names, ps
  from public.player_points_between(p_cutoff - interval '7 days', p_cutoff, p_zone) t where t.points > 0;
  if ids is null or array_length(ids, 1) < 6 or ps[5] <> ps[6] then return; end if;
  select count(*) into above from unnest(ps) x where x > ps[5];
  slots := 5 - above;
  insert into public.polls (kind, question, active, window_end, closes_at, slots, zone_id)
  values ('totw_tie', 'تعادل في تشكيلة الجولة — مين يدخل؟', true, p_cutoff,
          p_cutoff + interval '20 hours', slots, p_zone)
  returning id into pid;
  insert into public.poll_options (poll_id, label, player_id)
  select pid, names[i], ids[i] from generate_subscripts(ids, 1) i where ps[i] = ps[5];
  insert into public.notifications (title, body, kind, audience, zone_id)
  values ('⚖️ تعادل في تشكيلة الجولة', 'لاعيبة جابوا نفس النقط على آخر ' ||
          case when slots = 1 then 'مكان' else slots || ' أماكن' end || ' — صوّت لحد نص الليل', 'vote',
          case when p_zone is null then 'all' else 'zone' end, p_zone);
end $$;

create or replace function public.fn_totw_tie(p_cutoff timestamptz)
returns void language plpgsql security definer set search_path = public as $$
declare z record; any_zone boolean := false;
begin
  for z in select distinct m.zone_id from public.matches m
           where m.date_time > p_cutoff - interval '7 days' and m.date_time <= p_cutoff and m.zone_id is not null loop
    any_zone := true;
    perform public.fn_totw_tie_zone(p_cutoff, z.zone_id);
  end loop;
  if not any_zone then perform public.fn_totw_tie_zone(p_cutoff, null); end if;   -- ماتشات عامة بس
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 18) BADGES — الشارات والإنجازات                                  ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.user_badges (
  user_id   uuid references public.profiles(id) on delete cascade,
  badge     text not null,
  tier      int not null default 0,       -- 0 = لسه · 1 برونز · 2 فضة · 3 دهب
  value     int not null default 0,       -- التقدّم
  earned_at timestamptz,
  primary key (user_id, badge)
);
alter table public.user_badges enable row level security;
drop policy if exists "badges read" on public.user_badges;
create policy "badges read" on public.user_badges for select to authenticated using (true);

-- حدود المستويات (نفس BadgeCatalog في Dart)
create or replace function public.fn_badge_tier(b text, v int)
returns int language sql immutable as $$
  select case
    when b = 'first_100' then case when v between 1 and 100 then 3 when v between 1 and 500 then 2
                                   when v between 1 and 1000 then 1 else 0 end
    else (select count(*)::int from unnest(case b
      when 'streak' then array[5,10,25] when 'addict' then array[10,25,50]
      when 'early_bird' then array[1,10,30] when 'last_second' then array[1,5,15]
      when 'hawk_eye' then array[1,3,10] when 'right_captain' then array[1,5,15]
      when 'differential' then array[1,5,15] when 'golden_five' then array[1,5,15]
      when 'bench_betrayal' then array[1,5,15] when 'saviour' then array[1,3,10]
      when 'round_king' then array[1,3,10] when 'day_king' then array[1,5,15]
      when 'top10' then array[1,5,15] when 'rocket' then array[1,3,10]
      when 'record' then array[1,3,5] when 'league_leader' then array[1,5,15]
      when 'oracle' then array[1,3,10] when 'people_voice' then array[1,5,15]
      when 'critic' then array[5,20,50] when 'influencer' then array[5,15,50]
      when 'real_captain' then array[10,25,50] when 'beloved' then array[1,3,10]
      when 'people_captain' then array[1,3,10] when 'letdown' then array[1,2,3]
      else array[1,5,15] end) t where v >= t) end;
$$;

create or replace function public.fn_badge_name(b text)
returns text language sql immutable as $$
  select case b
    when 'streak' then 'مش بيفوّت' when 'addict' then 'المدمن' when 'first_100' then 'من الأوائل'
    when 'early_bird' then 'صاحي بدري' when 'last_second' then 'آخر ثانية'
    when 'hawk_eye' then 'عين الصقر' when 'right_captain' then 'الكابتن الصح'
    when 'differential' then 'ضد التيار' when 'golden_five' then 'الخماسي الذهبي'
    when 'bench_betrayal' then 'الاحتياطي خاني' when 'saviour' then 'المنقذ'
    when 'round_king' then 'ملك الجولة' when 'day_king' then 'ملك اليوم' when 'top10' then 'التوب ١٠'
    when 'rocket' then 'الصاروخ' when 'record' then 'رقم قياسي' when 'league_leader' then 'البطل'
    when 'oracle' then 'العرّاف' when 'people_voice' then 'صوت الشعب' when 'critic' then 'ناقد رياضي'
    when 'influencer' then 'المؤثر' when 'real_captain' then 'الكابتن الحقيقي'
    when 'beloved' then 'المحبوب' when 'people_captain' then 'كابتن الشعب' when 'letdown' then 'خيّب الظن'
    else b end;
$$;

create or replace function public.fn_set_badge(u uuid, b text, v int)
returns void language plpgsql security definer set search_path = public as $$
declare t int := public.fn_badge_tier(b, coalesce(v, 0)); old int;
begin
  v := coalesce(v, 0);
  select tier into old from public.user_badges where user_id = u and badge = b;
  if old is null then
    if v = 0 then return; end if;
    insert into public.user_badges (user_id, badge, tier, value, earned_at)
    values (u, b, t, v, case when t > 0 then now() end);
  else
    update public.user_badges set value = v, tier = greatest(tier, t),
      earned_at = case when t > tier then now() else earned_at end
    where user_id = u and badge = b;
  end if;
  if t > coalesce(old, 0) then
    insert into public.notifications (title, body, kind, user_id)
    values ('🏅 شارة جديدة: ' || public.fn_badge_name(b),
            case t when 1 then 'برونز 🥉' when 2 then 'فضة 🥈' else 'دهب 🥇' end || ' — افتح إنجازاتك وشيّرها',
            'badge', u);
  end if;
end $$;

create or replace function public.fn_bump_badge(u uuid, b text)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.fn_set_badge(u, b,
    coalesce((select value from public.user_badges where user_id = u and badge = b), 0) + 1);
end $$;

-- حقائق كل لاعب في تشكيلات اليوزر في الجولات اللي خلصت
drop function if exists public.fn_user_pick_facts(uuid);
create or replace function public.fn_user_pick_facts(u uuid)
returns table(round_end timestamptz, player_id uuid, status text, is_captain boolean, is_vice boolean,
              saved_at timestamptz, deadline timestamptz, base int, played boolean, goals int,
              round_max int, owner_pct numeric, chip text)
language sql stable security definer set search_path = public as $$
  with mine as (
    select rp.round_end, rp.player_id, rp.status, rp.is_captain, rp.is_vice, rp.saved_at
    from public.round_picks rp where rp.user_id = u and rp.round_end <= now()
  ), rounds as (
    select distinct mine.round_end from mine
  ), ev as (
    select rounds.round_end, e.player_id, sum(public.fn_event_points(e.type, pl.position))::int as pts,
           (count(*) filter (where e.type = 'goal'))::int as goals
    from rounds
    join public.matches m on m.date_time > rounds.round_end - interval '7 days' and m.date_time <= rounds.round_end
                         and m.review_status <> 'void'
    join public.events e on e.match_id = m.id
    join public.players pl on pl.id = e.player_id
    group by rounds.round_end, e.player_id
  ), mx as (
    select ev.round_end, max(ev.pts) as mx from ev group by ev.round_end
  ), own as (
    select rp.round_end, rp.player_id, count(*)::numeric as n from public.round_picks rp
    where rp.round_end in (select rounds.round_end from rounds) group by rp.round_end, rp.player_id
  ), tot as (
    select rp.round_end, count(distinct rp.user_id)::numeric as n from public.round_picks rp
    where rp.round_end in (select rounds.round_end from rounds) group by rp.round_end
  )
  select mine.round_end, mine.player_id, mine.status, mine.is_captain, mine.is_vice, mine.saved_at,
    public.fn_round_deadline(mine.round_end), coalesce(ev.pts, 0), ev.player_id is not null, coalesce(ev.goals, 0),
    coalesce(mx.mx, 0), round(coalesce(own.n, 0) * 100 / greatest(tot.n, 1), 1),
    (select c.chip from public.chip_uses c where c.user_id = u and c.week_cutoff = mine.round_end)
  from mine
  left join ev on ev.round_end = mine.round_end and ev.player_id = mine.player_id
  left join mx on mx.round_end = mine.round_end
  left join own on own.round_end = mine.round_end and own.player_id = mine.player_id
  left join tot on tot.round_end = mine.round_end;
$$;

-- الشارات الشخصية لليوزر (بتتحسب لما يبقى عنده نشاط جديد)
create or replace function public.fn_award_badges(u uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v int;
begin
  drop table if exists _pf;
  create temp table _pf as select * from public.fn_user_pick_facts(u);

  perform public.fn_set_badge(u, 'hawk_eye',
    (select count(distinct round_end) from _pf where is_captain and goals >= 3)::int);
  perform public.fn_set_badge(u, 'right_captain',
    (select count(distinct round_end) from _pf where is_captain and base > 0 and base >= round_max)::int);
  perform public.fn_set_badge(u, 'differential',
    (select count(distinct round_end) from _pf where status = 'starting' and base >= 10 and owner_pct < 10)::int);
  perform public.fn_set_badge(u, 'golden_five', (select count(*) from (
    select round_end from _pf where status = 'starting' group by round_end
    having count(*) filter (where base > 0) = 5) x)::int);
  perform public.fn_set_badge(u, 'bench_betrayal', (select count(*) from (
    select round_end from _pf group by round_end
    having coalesce(max(chip), '') <> 'bench_boost'
       and coalesce(sum(base) filter (where status = 'bench'), 0) > coalesce(sum(base) filter (where status = 'starting'), 0)) x)::int);
  perform public.fn_set_badge(u, 'saviour', (select count(*) from (
    select round_end from _pf group by round_end
    having not bool_or(is_captain and played)
       and coalesce(max(base) filter (where is_vice), 0) >= 8) x)::int);
  perform public.fn_set_badge(u, 'early_bird', (select count(*) from (
    select round_end from _pf group by round_end
    having max(saved_at) <= max(deadline) - interval '24 hours') x)::int);
  perform public.fn_set_badge(u, 'last_second', (select count(*) from (
    select round_end from _pf group by round_end
    having max(saved_at) > max(deadline) - interval '1 minute') x)::int);
  drop table if exists _pf;

  -- مش بيفوّت: أطول سلسلة جولات ورا بعض فيها تشكيلة
  select coalesce(max(n), 0) into v from (
    select count(*) as n from (
      select wk - (row_number() over (order by wk)) * interval '7 days' as grp
      from (select distinct rp.round_end as wk from public.round_picks rp
            where rp.user_id = u and rp.round_end <= now()) w
    ) g group by grp) s;
  perform public.fn_set_badge(u, 'streak', v);

  -- المدمن: كام جولة لعبتها
  perform public.fn_set_badge(u, 'addict', (select count(distinct rp.round_end) from public.round_picks rp
    where rp.user_id = u and rp.round_end <= now())::int);

  perform public.fn_set_badge(u, 'oracle', (select count(*) from public.predictions pr
    join public.matches m on m.id = pr.match_id
    where pr.user_id = u and m.is_challenge and m.status = 'finished'
      and pr.score_a = m.score_a and pr.score_b = m.score_b)::int);
  perform public.fn_set_badge(u, 'critic',
    (select count(distinct match_id) from public.player_ratings where user_id = u)::int);
  perform public.fn_set_badge(u, 'people_voice', (select count(*) from public.poll_votes pv
    join public.polls p on p.id = pv.poll_id
    where pv.user_id = u and not p.active and pv.option_id = public.fn_poll_winner(p.id))::int);
  perform public.fn_set_badge(u, 'influencer',
    (select count(*) from public.profiles where referred_by = u)::int);
  perform public.fn_set_badge(u, 'real_captain', (select coalesce(max(c), 0) from (
    select count(*) as c from public.leagues l join public.league_members lm on lm.league_id = l.id
    where l.owner_id = u group by l.id) x)::int);
  perform public.fn_set_badge(u, 'first_100', (select count(*) from public.profiles
    where created_at <= (select created_at from public.profiles where id = u))::int);
  -- رقم قياسي: كام مرة نقطك في جولة كسرت أعلى رقم في تاريخ التطبيق وقتها
  perform public.fn_set_badge(u, 'record', (select count(*) from public.user_round_points a
    where a.user_id = u and a.round_end <= now() and a.points > 0
      and a.points > coalesce((select max(b.points) from public.user_round_points b
                               where b.round_end < a.round_end), 0))::int);
end $$;

-- شارات الجولة (بتتحسب مرة واحدة لما الجولة تخلص السبت ٤ العصر)
create or replace function public.fn_round_badges(p_cutoff timestamptz)
returns void language plpgsql security definer set search_path = public as $$
declare f timestamptz := p_cutoff - interval '7 days'; r record; best int;
begin
  drop table if exists _rt;
  create temp table _rt as
    select urp.user_id, urp.points as pts from public.user_round_points urp where urp.round_end = p_cutoff;

  select max(pts) into best from _rt;
  if best > 0 then
    for r in select user_id from _rt where pts = best loop
      perform public.fn_bump_badge(r.user_id, 'round_king');
    end loop;
  end if;
  for r in select user_id from (select user_id, rank() over (order by pts desc) as rk from _rt where pts > 0) x
           where rk <= 10 loop
    perform public.fn_bump_badge(r.user_id, 'top10');
  end loop;

  -- الصاروخ: طلع ٢٠ مركز أو أكتر في الترتيب العام في الجولة دي
  for r in
    with b as (select urp.user_id, sum(urp.points) as s from public.user_round_points urp
               where urp.round_end <= f group by urp.user_id),
         a as (select urp.user_id, sum(urp.points) as s from public.user_round_points urp
               where urp.round_end <= p_cutoff group by urp.user_id),
         rb as (select user_id, rank() over (order by s desc) as rk from b),
         ra as (select user_id, rank() over (order by s desc) as rk from a)
    select ra.user_id from ra join rb on rb.user_id = ra.user_id where rb.rk - ra.rk >= 20 loop
    perform public.fn_bump_badge(r.user_id, 'rocket');
  end loop;

  -- ملك اليوم: الأعلى في نقط أساسييه (والكابتن ×٢) في كل يوم من أيام الجولة
  for r in
    with d as (select rp.user_id, (m.date_time at time zone 'Africa/Cairo')::date as dy,
                      sum(public.fn_event_points(e.type, pl.position) * case when rp.is_captain then 2 else 1 end) as s
               from public.round_picks rp
               join public.events e on e.player_id = rp.player_id
               join public.matches m on m.id = e.match_id
               join public.players pl on pl.id = rp.player_id
               where rp.round_end = p_cutoff and rp.status = 'starting' and m.review_status <> 'void'
                 and m.date_time > f and m.date_time <= p_cutoff
               group by 1, 2),
         mx as (select dy, max(s) as mx from d group by dy)
    select d.user_id from d join mx on mx.dy = d.dy where d.s = mx.mx and mx.mx > 0 loop
    perform public.fn_bump_badge(r.user_id, 'day_king');
  end loop;

  -- البطل: الأول في دوري (٣ أعضاء أو أكتر) لما الجولة قفلت
  for r in select distinct on (lm.league_id) lm.user_id from public.league_members lm
           join public.profiles p on p.id = lm.user_id
           where p.total_points > 0
             and (select count(*) from public.league_members x where x.league_id = lm.league_id) >= 3
           order by lm.league_id, p.total_points desc loop
    perform public.fn_bump_badge(r.user_id, 'league_leader');
  end loop;

  -- شارات اللاعيبة الموثّقين
  for r in select pl.user_id from public.player_window_stats(f, p_cutoff) s
           join public.players pl on pl.id = s.id where pl.user_id is not null and s.ownership > 50 loop
    perform public.fn_bump_badge(r.user_id, 'beloved');
  end loop;
  for r in
    with c as (select rp.player_id, count(*) as n from public.round_picks rp
               where rp.is_captain and rp.round_end = p_cutoff group by rp.player_id)
    select pl.user_id from c join public.players pl on pl.id = c.player_id
    where pl.user_id is not null and c.n = (select max(n) from c) loop
    perform public.fn_bump_badge(r.user_id, 'people_captain');
  end loop;
  for r in
    select pl.user_id from (
      select rp.player_id from public.round_picks rp
      where rp.is_captain and rp.round_end = p_cutoff
      group by rp.player_id having count(*) >= 30) c
    join public.players pl on pl.id = c.player_id
    where pl.user_id is not null
      and coalesce((select sum(public.fn_event_points(e.type, pl.position)) from public.events e
                    join public.matches m on m.id = e.match_id
                    where e.player_id = c.player_id and m.review_status <> 'void'
                      and m.date_time > f and m.date_time <= p_cutoff), 0) <= 0 loop
    perform public.fn_bump_badge(r.user_id, 'letdown');
  end loop;

  update public.profiles set badges_dirty = true where id in (select user_id from _rt);
  drop table if exists _rt;
end $$;

-- الشارات الشخصية لليوزرز اللي عندهم نشاط جديد (دفعة محدودة كل مرة)
create or replace function public.fn_award_dirty_badges(p_limit int)
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from public.profiles where badges_dirty limit p_limit loop
    perform public.fn_award_badges(r.id);
    update public.profiles set badges_dirty = false where id = r.id;
  end loop;
end $$;

-- أي نشاط جديد (توقّع/تقييم/تصويت) → شاراته تتحسب في الدورة الجاية
create or replace function public.trg_mark_badges_dirty()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update public.profiles set badges_dirty = true where id = new.user_id and not badges_dirty;
  return null;
end $$;
drop trigger if exists predictions_dirty on public.predictions;
create trigger predictions_dirty after insert on public.predictions
for each row execute function public.trg_mark_badges_dirty();
drop trigger if exists ratings_dirty on public.player_ratings;
create trigger ratings_dirty after insert on public.player_ratings
for each row execute function public.trg_mark_badges_dirty();
drop trigger if exists votes_dirty on public.poll_votes;
create trigger votes_dirty after insert on public.poll_votes
for each row execute function public.trg_mark_badges_dirty();


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 19) TICK — مهمة كل ١٠ دقايق                                    ║
-- ╚═══════════════════════════════════════════════════════════════╝

create table if not exists public.app_jobs (
  key     text primary key,
  done_at timestamptz not null default now()
);
alter table public.app_jobs enable row level security;   -- مفيش سياسات = محدش يوصله من التطبيق

-- اللاعيبة الموثّقين: "انت كابتن عند N واحد" أول ما ديدلاين الجولة يعدّي (مرة واحدة)
create or replace function public.fn_notify_captains()
returns void language plpgsql security definer set search_path = public as $$
declare r timestamptz := public.fn_open_round() - interval '7 days';   -- آخر جولة ديدلاينها عدّى
begin
  if now() < public.fn_round_deadline(r) then return; end if;
  insert into public.app_jobs (key) values ('captains:' || to_char(r at time zone 'UTC', 'YYYYMMDDHH24'))
  on conflict do nothing;
  if not found then return; end if;
  insert into public.notifications (title, body, kind, user_id)
  select '🔥 انت كابتن عند ' || count(*) || ' واحد', 'في الجولة اللي جاية — ورّيهم', 'status', pl.user_id
  from public.round_picks p join public.players pl on pl.id = p.player_id
  where p.round_end = r and p.is_captain and pl.user_id is not null
  group by pl.user_id;
end $$;

-- p_limit: كام يوزر تتحسب شاراتهم في الدورة (pg_cron: 300 · التطبيق: 20)
create or replace function public.fn_tick(p_limit int default 20)
returns void language plpgsql security definer set search_path = public as $$
declare last timestamptz; c timestamptz; cp timestamptz; k text;
begin
  if not pg_try_advisory_xact_lock(424242) then return; end if;
  select done_at into last from public.app_jobs where key = 'tick';
  if last is not null and last > now() - interval '4 minutes' then return; end if;
  insert into public.app_jobs (key, done_at) values ('tick', now())
  on conflict (key) do update set done_at = excluded.done_at;

  perform public.fn_close_ratings();
  perform public.fn_notify_captains();
  perform public.fn_close_polls();
  perform public.fn_update_tiebreak();
  perform public.fn_review_tick();

  c := public.fn_week_cutoff(now());
  cp := c - interval '7 days';                         -- آخر جولة قفلت
  k := 'round:' || to_char(cp at time zone 'UTC', 'YYYYMMDDHH24');
  if now() > cp then
    insert into public.app_jobs (key) values (k) on conflict do nothing;
    if found then
      if now() < cp + interval '20 hours' then
        perform public.fn_totw_tie(cp);                -- التعادل بيتعمل بس وقت عرض النهائي
      end if;
      perform public.fn_round_badges(cp);
    end if;
  end if;

  perform public.fn_award_dirty_badges(least(greatest(p_limit, 1), 300));
end $$;
grant execute on function public.fn_tick(int) to authenticated;

-- جدولة كل ١٠ دقايق (لو pg_cron مش متفعّل، التطبيق بينادي fn_tick كاحتياطي)
do $$ begin
  create extension if not exists pg_cron;
  perform cron.schedule('khomasi-tick', '*/10 * * * *', 'select public.fn_tick(300)');
exception when others then
  raise notice 'pg_cron مش متاح: فعّله من Database → Extensions وشغّل الملف تاني';
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 20) PUSH — أي إشعار بيتسجّل → push أوتوماتيك                   ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- الـ trigger بيبعت id الإشعار لـ Edge Function اسمها push (pg_net)، وهي بتبعت FCM:
--   all → topic "all" · user → توكن اليوزر · match → توكنات متابعين الماتش.
-- النشر: npx supabase functions deploy push --no-verify-jwt --project-ref jhofyglkpwguzodbeyia

do $$ begin
  create extension if not exists pg_net;
exception when others then
  raise notice 'pg_net مش متاح: فعّله من Database → Extensions وشغّل الملف تاني';
end $$;
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.settings (key text primary key, value text not null);
insert into private.settings (key, value)
values ('push_url', 'https://jhofyglkpwguzodbeyia.supabase.co/functions/v1/push')
on conflict (key) do nothing;
insert into private.settings (key, value)
values ('push_secret', replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''))
on conflict (key) do nothing;

-- الـ Edge Function بتتأكد إن الطلب جاي من الداتابيز (service_role بس يقدر يناديها)
create or replace function public.push_secret_ok(s text)
returns boolean language sql stable security definer set search_path = public, private as $$
  select exists (select 1 from private.settings where key = 'push_secret' and value = s);
$$;
revoke execute on function public.push_secret_ok(text) from public, anon, authenticated;
grant execute on function public.push_secret_ok(text) to service_role;

create or replace function public.trg_notification_push()
returns trigger language plpgsql security definer set search_path = public, private as $$
declare u text; s text;
begin
  select value into u from private.settings where key = 'push_url';
  select value into s from private.settings where key = 'push_secret';
  if u is not null then
    perform net.http_post(url := u, body := jsonb_build_object('id', new.id, 'secret', s),
                          headers := jsonb_build_object('Content-Type', 'application/json'));
  end if;
  return new;
exception when others then
  return new;   -- الـ push عمره ما يوقّف تسجيل الإشعار
end $$;
drop trigger if exists notification_push on public.notifications;
create trigger notification_push after insert on public.notifications
for each row execute function public.trg_notification_push();

-- Realtime للجداول اللي اليوزر بيشوفها (أي تعديل من المدير يظهر فورًا)
do $$
declare t text;
begin
  foreach t in array array['lineups', 'players', 'events', 'polls', 'venues', 'picks', 'round_picks', 'matches',
                           'bookings', 'user_badges', 'venue_reviews'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 21) MATCH INTEGRITY — المنظّمين + تأكيد الطرفين + الاعتماد       ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- الفكرة: اللي بيدخّل الأهداف ميستفيدش منها، وورقة الماتش بتتأكد من لاعيبة الفريقين.
--   ١) المنظّم = يوزر الأدمن وافق على طلبه. بيدير ماتشاته بس، ومينفعش يختار منها في الفانتازي.
--   ٢) الماتش يخلص → pending: اللاعيبة الموثّقين في التشكيلة يأكدوا ✅ أو يعترضوا ❌.
--   ٣) مفيش اعتراض خلال ١٢ ساعة → معتمد لوحده. لو فيه علامة غرابة → لازم تأكيد صريح من الفريقين.
--   ٤) اعتراض → disputed → الأدمن يحكم (اعتماد / إلغاء الماتش / إعادة المراجعة).
--   نقط الماتش بتبان لايف "مبدئية"، والإجمالي والترتيب بيحسبوا المعتمد بس (fn_user_points).

create table if not exists public.match_reviews (
  match_id   uuid references public.matches(id) on delete cascade,
  user_id    uuid references public.profiles(id) on delete cascade,
  team       text not null,
  ok         boolean not null,
  note       text check (note is null or length(note) <= 300),
  created_at timestamptz not null default now(),
  primary key (match_id, user_id)
);
alter table public.match_reviews enable row level security;
drop policy if exists "match reviews read" on public.match_reviews;
create policy "match reviews read" on public.match_reviews for select to authenticated using (
  user_id = auth.uid() or public.is_manager()
  or exists (select 1 from public.matches m where m.id = match_id and m.organizer_id = auth.uid())
);
-- مفيش كتابة مباشرة: بدالة review_match بس

-- منطقة فريق بالاسم
create or replace function public.fn_team_zone(p_name text)
returns int language sql stable security definer set search_path = public as $$
  select zone_id from public.teams where lower(trim(name)) = lower(trim(p_name));
$$;

create or replace function public.fn_ensure_team(p_name text)
returns void language sql security definer set search_path = public as $$
  insert into public.teams (name)
  select trim(p_name)
  where not exists (select 1 from public.teams where lower(trim(name)) = lower(trim(p_name)));
$$;

-- المنظّم: الماتش لازم يتعمل قبل ديدلاين جولته (عشان اليوزرز يختاروا وهما عارفين مين هيلعب)
create or replace function public.fn_check_round_open(p_when timestamptz)
returns void language plpgsql stable as $$
begin
  if now() >= public.fn_round_deadline(public.fn_week_cutoff(p_when)) then
    raise exception 'ديدلاين الجولة دي عدّى (السبت ١٢ الضهر) — حط الماتش في الجولة الجاية';
  end if;
end $$;

-- المنظّم: الفريقين لازم يكونوا بتوعه
create or replace function public.fn_check_my_teams(p_teams text[])
returns void language plpgsql stable security definer set search_path = public as $$
begin
  if (select count(*) from public.teams t
      where t.owner_id = auth.uid() and lower(trim(t.name)) in (lower(trim(p_teams[1])), lower(trim(p_teams[2])))) < 2 then
    raise exception 'الفريقين لازم يكونوا من فرقك — ضيفهم من "فرقي"';
  end if;
end $$;

create or replace function public.fn_reset_reviews(p_match uuid)
returns void language sql security definer set search_path = public as $$
  delete from public.match_reviews where match_id = p_match;
$$;

-- حماية الماتش من التطبيق: المنظّم ميقدرش يلعب في حالة الاعتماد ولا الأعمدة بتاعة السيرفر
create or replace function public.trg_matches_guard()
returns trigger language plpgsql as $$
declare client boolean := current_user in ('authenticated', 'anon') and not public.is_manager();
begin
  if tg_op = 'INSERT' then
    if client then
      new.organizer_id := auth.uid();
      new.status := 'upcoming';
      new.score_a := null;
      new.score_b := null;
      new.review_status := 'open';
      new.review_due := null;
      new.flags := '{}';
      new.is_challenge := false;
      new.motm_player_id := null;
      new.motm_done := false;
      new.captains_notified := false;
      new.tiebreak_done := false;
      if new.date_time < now() + interval '1 hour' then
        raise exception 'ميعاد الماتش لازم يكون بعد ساعة على الأقل';
      end if;
      if coalesce(array_length(new.teams, 1), 0) <> 2 or new.teams[1] = new.teams[2] then
        raise exception 'لازم فريقين مختلفين';
      end if;
      perform public.fn_check_my_teams(new.teams);
      perform public.fn_check_round_open(new.date_time);
    end if;
    new.zone_id := coalesce(public.fn_team_zone(new.teams[1]), new.zone_id);
    return new;
  end if;

  if client then
    new.organizer_id := old.organizer_id;
    new.review_status := old.review_status;
    new.review_due := old.review_due;
    new.flags := old.flags;
    new.is_challenge := old.is_challenge;
    new.motm_player_id := old.motm_player_id;
    new.motm_done := old.motm_done;
    new.captains_notified := old.captains_notified;
    new.tiebreak_done := old.tiebreak_done;
    if (new.date_time, new.teams) is distinct from (old.date_time, old.teams) then
      if now() >= old.date_time - interval '1 hour' then
        raise exception 'مينفعش تغيّر الميعاد أو الفرق بعد قفل التشكيلات';
      end if;
      if new.date_time < now() + interval '1 hour' then
        raise exception 'ميعاد الماتش لازم يكون بعد ساعة على الأقل';
      end if;
      if new.teams is distinct from old.teams then perform public.fn_check_my_teams(new.teams); end if;
      if new.date_time is distinct from old.date_time then perform public.fn_check_round_open(new.date_time); end if;
    end if;
    if old.status = 'finished' and new.status <> 'finished' then
      raise exception 'الماتش خلص — لو فيه غلط كلّم الإدارة';
    end if;
    if new.status = 'finished' and old.status <> 'finished' and now() < old.date_time then
      raise exception 'الماتش لسه مبدأش';
    end if;
    -- تعديل النتيجة بعد النهاية = علامة غرابة + التأكيدات تتلغي
    if old.status = 'finished' and (new.score_a, new.score_b) is distinct from (old.score_a, old.score_b) then
      new.flags := array(select distinct unnest(old.flags || array['late_edit']));
      new.review_due := now() + interval '12 hours';
      perform public.fn_reset_reviews(old.id);
    end if;
  end if;

  if new.teams is distinct from old.teams then
    new.zone_id := coalesce(public.fn_team_zone(new.teams[1]), new.zone_id);
  end if;

  -- الأدمن رجّع الماتش لـ "لسه" → المراجعة تبدأ من الأول
  if old.status = 'finished' and new.status <> 'finished' then
    new.review_status := 'open';
    new.review_due := null;
    new.flags := '{}';
    perform public.fn_reset_reviews(old.id);
  end if;
  return new;
end $$;
drop trigger if exists matches_guard on public.matches;
create trigger matches_guard before insert or update on public.matches
for each row execute function public.trg_matches_guard();

-- حماية اللاعيبة: المنظّم ميقدرش يغيّر الإحصائيات ولا التوثيق
create or replace function public.trg_players_guard()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_manager() then
    if tg_op = 'INSERT' then
      new.created_by := auth.uid();
      new.user_id := null;
      new.total_points := 0;
      new.form := 0;
      new.goals := 0;
      new.assists := 0;
      new.clean_sheets := 0;
      new.yellow_cards := 0;
    else
      new.created_by := old.created_by;
      new.user_id := old.user_id;
      new.total_points := old.total_points;
      new.form := old.form;
      new.goals := old.goals;
      new.assists := old.assists;
      new.clean_sheets := old.clean_sheets;
      new.yellow_cards := old.yellow_cards;
    end if;
    if not exists (select 1 from public.teams t
                   where lower(trim(t.name)) = lower(trim(new.team)) and t.owner_id = auth.uid()) then
      raise exception 'الفريق ده مش بتاعك — ضيفه من "فرقي" الأول';
    end if;
  elsif trim(coalesce(new.team, '')) <> '' then
    perform public.fn_ensure_team(new.team);          -- الأدمن: أي اسم جديد بيبقى فريق (من غير منطقة)
  end if;
  new.zone_id := public.fn_team_zone(new.team);
  return new;
end $$;
drop trigger if exists players_guard on public.players;
create trigger players_guard before insert or update on public.players
for each row execute function public.trg_players_guard();

-- علامات الغرابة (مش ممنوعات — بس الماتش ميتعتمدش بالسكوت):
--   score_mismatch  الأهداف المسجّلة مش نفس النتيجة
--   big_margin      فرق ١٠ أهداف أو أكتر
--   organizer_stats المنظّم نفسه عمل ٣ أهداف/أسيست أو أكتر
--   new_organizer   المنظّم عنده أقل من ٥ ماتشات معتمدة
--   late_edit       (بيتحط لوحده) أحداث أو نتيجة اتعدّلت بعد النهاية
create or replace function public.fn_match_flags(p_match uuid)
returns text[] language sql stable security definer set search_path = public as $$
  with m as (select * from public.matches where id = p_match),
  g as (
    select
      count(*) filter (where (e.type = 'goal' and pl.team = m.teams[1]) or (e.type = 'ownGoal' and pl.team = m.teams[2])) as ga,
      count(*) filter (where (e.type = 'goal' and pl.team = m.teams[2]) or (e.type = 'ownGoal' and pl.team = m.teams[1])) as gb,
      count(*) filter (where e.type in ('goal', 'assist') and pl.user_id = m.organizer_id) as org
    from m
    left join public.events e on e.match_id = m.id
    left join public.players pl on pl.id = e.player_id
  )
  select array_remove(array[
    case when g.ga <> coalesce(m.score_a, 0) or g.gb <> coalesce(m.score_b, 0) then 'score_mismatch' end,
    case when abs(coalesce(m.score_a, 0) - coalesce(m.score_b, 0)) >= 10 then 'big_margin' end,
    case when g.org >= 3 then 'organizer_stats' end,
    case when (select count(*) from public.matches x
               where x.organizer_id = m.organizer_id and x.review_status = 'approved') < 5 then 'new_organizer' end
  ], null)
  from m, g;
$$;

-- الماتش خلص → إشعار بالنتيجة + (لو منظّم) مراجعة ١٢ ساعة + طلب تأكيد من اللاعيبة الموثّقين
create or replace function public.fn_start_review(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  select * into m from public.matches where id = p_match;
  perform public.fn_notify_match(p_match, 'انتهى الماتش 🏁',
    m.teams[1] || ' ' || m.score_a || ' - ' || m.score_b || ' ' || m.teams[2], 'match');
  -- ماتشات الأدمن معتمدة على طول
  if m.organizer_id is null or exists (select 1 from public.profiles where id = m.organizer_id and role = 'manager') then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
    return;
  end if;
  update public.matches
  set review_status = 'pending', review_due = now() + interval '12 hours',
      flags = array(select distinct unnest(m.flags || public.fn_match_flags(p_match)))
  where id = p_match;
  perform public.fn_ask_reviewers(p_match);
end $$;

create or replace function public.fn_ask_reviewers(p_match uuid)
returns void language sql security definer set search_path = public as $$
  insert into public.notifications (title, body, kind, user_id, match_id)
  select distinct on (pl.user_id) '📋 أكّد ورقة الماتش',
         m.teams[1] || ' ' || m.score_a || ' - ' || m.score_b || ' ' || m.teams[2] || ' — النتيجة والأهداف صح؟',
         'review', pl.user_id, m.id
  from public.matches m
  join public.lineups l on l.match_id = m.id
  join public.players pl on pl.id = l.player_id
  where m.id = p_match and pl.user_id is not null and pl.user_id is distinct from m.organizer_id;
$$;

create or replace function public.trg_match_review()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'finished' and old.status is distinct from 'finished' then
    perform public.fn_start_review(new.id);
  end if;
  return null;
end $$;
drop trigger if exists match_review on public.matches;
create trigger match_review after update on public.matches
for each row execute function public.trg_match_review();

-- المنظّم عدّل أحداث بعد النهاية → علامة late_edit + التأكيدات تتلغي + الـ ١٢ ساعة تبدأ من الأول
create or replace function public.fn_mark_late_edit(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update public.matches
  set flags = array(select distinct unnest(flags || array['late_edit'])), review_due = now() + interval '12 hours'
  where id = p_match and status = 'finished' and review_status = 'pending';
  if found then perform public.fn_reset_reviews(p_match); end if;
end $$;

create or replace function public.trg_events_late()
returns trigger language plpgsql as $$
begin
  if current_user in ('authenticated', 'anon') and not public.is_manager() then
    perform public.fn_mark_late_edit(coalesce(new.match_id, old.match_id));
  end if;
  return null;
end $$;
drop trigger if exists events_late on public.events;
create trigger events_late after insert or update or delete on public.events
for each row execute function public.trg_events_late();

-- الفريق اللي أنا لاعب موثّق فيه في الماتش ده (null = مش من حقي أراجع)
create or replace function public.fn_reviewer_team(p_match uuid, p_user uuid)
returns text language sql stable security definer set search_path = public as $$
  select pl.team from public.lineups l
  join public.players pl on pl.id = l.player_id
  join public.matches m on m.id = l.match_id
  where l.match_id = p_match and pl.user_id = p_user and m.organizer_id is distinct from p_user
  limit 1;
$$;

-- ✅ / ❌ على ورقة الماتش
create or replace function public.review_match(p_match uuid, p_ok boolean, p_note text default null)
returns text language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); m public.matches; t text; n text := nullif(trim(p_note), '');
begin
  if u is null then raise exception 'سجّل دخولك الأول'; end if;
  select * into m from public.matches where id = p_match for update;
  if not found or m.review_status <> 'pending' then raise exception 'الماتش مش مستني تأكيد'; end if;
  t := public.fn_reviewer_team(p_match, u);
  if t is null then raise exception 'لازم تكون لاعب موثّق في تشكيلة الماتش'; end if;
  if not p_ok and n is null then raise exception 'اكتب إيه الغلط'; end if;

  insert into public.match_reviews (match_id, user_id, team, ok, note)
  values (p_match, u, t, p_ok, left(n, 300))
  on conflict (match_id, user_id) do update set ok = excluded.ok, note = excluded.note, created_at = now();

  if not p_ok then
    update public.matches set review_status = 'disputed' where id = p_match;
    insert into public.notifications (title, body, kind, user_id, match_id)
    select '⚠️ اعتراض على ماتش', m.teams[1] || ' ضد ' || m.teams[2] || ' — ' || left(n, 120), 'review', p.id, p_match
    from public.profiles p where p.role = 'manager' or p.id = m.organizer_id;
    return 'disputed';
  end if;

  -- الفريقين أكّدوا → معتمد على طول
  if exists (select 1 from public.match_reviews r where r.match_id = p_match and r.ok and r.team = m.teams[1])
     and exists (select 1 from public.match_reviews r where r.match_id = p_match and r.ok and r.team = m.teams[2]) then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
    return 'approved';
  end if;
  return 'ok';
end $$;
grant execute on function public.review_match(uuid, boolean, text) to authenticated;

-- الماتشات اللي مستنية تأكيدي
create or replace function public.my_pending_reviews()
returns table(id uuid, teams text[], date_time timestamptz, score_a int, score_b int, flags text[], my_team text)
language sql stable security definer set search_path = public as $$
  select m.id, m.teams, m.date_time, m.score_a, m.score_b, m.flags, public.fn_reviewer_team(m.id, auth.uid())
  from public.matches m
  where m.review_status = 'pending'
    and public.fn_reviewer_team(m.id, auth.uid()) is not null
    and not exists (select 1 from public.match_reviews r where r.match_id = m.id and r.user_id = auth.uid())
  order by m.date_time desc;
$$;
grant execute on function public.my_pending_reviews() to authenticated;

-- كل دورة: المعتمد بالسكوت (من غير علامات)، والمعلّم عليه اللي عدّى وقته → تنبيه للأدمن مرة واحدة
create or replace function public.fn_review_tick()
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  update public.matches set review_status = 'approved', review_due = null
  where review_status = 'pending' and review_due <= now() and cardinality(flags) = 0;
  for r in select id, teams from public.matches
           where review_status = 'pending' and review_due <= now() and cardinality(flags) > 0 loop
    insert into public.app_jobs (key) values ('review-nudge:' || r.id) on conflict do nothing;
    if found then
      insert into public.notifications (title, body, kind, user_id, match_id)
      select '🔎 ماتش محتاج مراجعتك', r.teams[1] || ' ضد ' || r.teams[2] || ' — فيه علامات ومحدش أكّد', 'review', p.id, r.id
      from public.profiles p where p.role = 'manager';
    end if;
  end loop;
end $$;

-- (أدمن) الحكم: approve = اعتماد · void = إلغاء الماتش (الأحداث تتمسح والنقط تروح) · reopen = مراجعة من الأول
create or replace function public.resolve_match(p_match uuid, p_action text)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  select * into m from public.matches where id = p_match;
  if not found or m.status <> 'finished' then raise exception 'الماتش لسه مخلصش'; end if;
  if p_action = 'approve' then
    update public.matches set review_status = 'approved', review_due = null where id = p_match;
  elsif p_action = 'void' then
    delete from public.events where match_id = p_match;
    update public.matches set review_status = 'void', review_due = null where id = p_match;
    if m.organizer_id is not null then
      insert into public.notifications (title, body, kind, user_id, match_id)
      values ('🚫 ماتشك اتلغى', m.teams[1] || ' ضد ' || m.teams[2] || ' — الإدارة لغت الأحداث بعد المراجعة',
              'review', m.organizer_id, p_match);
    end if;
  elsif p_action = 'reopen' then
    perform public.fn_reset_reviews(p_match);
    update public.matches set review_status = 'pending', review_due = now() + interval '12 hours'
    where id = p_match;
    perform public.fn_ask_reviewers(p_match);
  else
    raise exception 'إجراء مش معروف';
  end if;
end $$;
grant execute on function public.resolve_match(uuid, text) to authenticated;

-- (أدمن) طابور المراجعة: الاعتراضات الأول، وبعدين المعلّم عليه
create or replace function public.admin_review_queue()
returns table(id uuid, teams text[], date_time timestamptz, score_a int, score_b int, review_status text,
              review_due timestamptz, flags text[], organizer_name text, reviews jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select m.id, m.teams, m.date_time, m.score_a, m.score_b, m.review_status, m.review_due, m.flags, o.name,
    coalesce((select jsonb_agg(jsonb_build_object('name', p.name, 'team', r.team, 'ok', r.ok, 'note', r.note)
                               order by r.created_at)
              from public.match_reviews r join public.profiles p on p.id = r.user_id
              where r.match_id = m.id), '[]'::jsonb)
  from public.matches m
  left join public.profiles o on o.id = m.organizer_id
  where m.review_status = 'disputed' or (m.review_status = 'pending' and cardinality(m.flags) > 0)
  order by (m.review_status = 'disputed') desc, m.date_time desc
  limit 100;
end $$;
grant execute on function public.admin_review_queue() to authenticated;

-- (منظّم/أدمن) إشعار "التشكيلة نزلت" — المنظّم مرة واحدة لكل ماتش
create or replace function public.notify_lineup(p_match uuid)
returns void language plpgsql security definer set search_path = public as $$
declare m public.matches;
begin
  if not (public.is_manager() or public.fn_organizes(p_match)) then raise exception 'مش ماتشك'; end if;
  select * into m from public.matches where id = p_match;
  if not public.is_manager() then
    insert into public.app_jobs (key) values ('lineup:' || p_match) on conflict do nothing;
    if not found then raise exception 'الإشعار اتبعت قبل كده'; end if;
  end if;
  perform public.fn_notify_match(p_match, 'تشكيلة نزلت ⚽',
    m.teams[1] || ' ضد ' || m.teams[2] || ' — اختار تشكيلتك قبل الديدلاين', 'lineup');
end $$;
grant execute on function public.notify_lineup(uuid) to authenticated;

-- ── طلبات "عايز أنظّم ماتشات" ──
create table if not exists public.organizer_requests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  note        text check (note is null or length(note) <= 300),
  status      text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at  timestamptz not null default now(),
  reviewed_at timestamptz
);
create unique index if not exists organizer_requests_one_pending on public.organizer_requests(user_id)
  where status = 'pending';
alter table public.organizer_requests enable row level security;
drop policy if exists "organizer requests read" on public.organizer_requests;
create policy "organizer requests read" on public.organizer_requests for select to authenticated
  using (user_id = auth.uid() or public.is_manager());
drop policy if exists "organizer requests insert" on public.organizer_requests;
create policy "organizer requests insert" on public.organizer_requests for insert to authenticated
  with check (user_id = auth.uid() and status = 'pending'
              and exists (select 1 from public.profiles p
                          where p.id = auth.uid() and p.role = 'user' and p.zone_id is not null));

create or replace function public.trg_organizer_request_notify()
returns trigger language plpgsql security definer set search_path = public as $$
declare un text;
begin
  select name into un from public.profiles where id = new.user_id;
  insert into public.notifications (title, body, kind, user_id)
  select '🧑‍⚖️ طلب منظّم ماتشات', coalesce(un, 'يوزر') || coalesce(' — ' || left(new.note, 100), ''), 'status', p.id
  from public.profiles p where p.role = 'manager';
  return new;
end $$;
drop trigger if exists organizer_request_notify on public.organizer_requests;
create trigger organizer_request_notify after insert on public.organizer_requests
for each row execute function public.trg_organizer_request_notify();

create or replace function public.pending_organizer_requests()
returns table(id uuid, user_id uuid, user_name text, phone text, note text, player_name text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  return query
  select r.id, r.user_id, p.name, p.phone, r.note,
         (select pl.name from public.players pl where pl.user_id = r.user_id), r.created_at
  from public.organizer_requests r join public.profiles p on p.id = r.user_id
  where r.status = 'pending' order by r.created_at;
end $$;
grant execute on function public.pending_organizer_requests() to authenticated;

create or replace function public.review_organizer_request(p_req uuid, p_approve boolean)
returns void language plpgsql security definer set search_path = public as $$
declare r public.organizer_requests;
begin
  if not public.is_manager() then raise exception 'للأدمن بس'; end if;
  select * into r from public.organizer_requests where id = p_req;
  if not found or r.status <> 'pending' then raise exception 'الطلب مش موجود أو اتراجع'; end if;
  update public.organizer_requests set status = case when p_approve then 'approved' else 'rejected' end,
         reviewed_at = now() where id = p_req;
  if p_approve then
    update public.profiles set role = 'organizer' where id = r.user_id and role = 'user';
    insert into public.notifications (title, body, kind, user_id)
    values ('✓ بقيت منظّم ماتشات', 'افتح "ماتشاتي كمنظّم" من حسابك واعمل أول ماتش', 'status', r.user_id);
  else
    insert into public.notifications (title, body, kind, user_id)
    values ('طلب التنظيم اترفض', 'تقدر تكلّم الإدارة وتقدّم تاني', 'status', r.user_id);
  end if;
end $$;
grant execute on function public.review_organizer_request(uuid, boolean) to authenticated;

-- الإجمالي بقى بيحسب المعتمد بس → نحدّث إجمالي الكل مرة (خفيفة دلوقتي — لو اليوزرز بقوا بالآلاف شيلها بعد أول تشغيل)
update public.profiles set total_points = public.fn_user_points(id) where id is not null;


-- ╔═══════════════════════════════════════════════════════════════╗
-- ║ 22) ZONES & TEAMS — المناطق والفرق بأصحابها                     ║
-- ╚═══════════════════════════════════════════════════════════════╝
-- اليوزر ليه منطقة: بيشوف ماتشاتها وإشعاراتها ونجم وتشكيلة الجولة بتاعتها، وميقدرش يعمل تشكيلة بره منطقته.
-- المنظّم بيعمل فرق في منطقته، والماتش لازم يكون بين فريقين من فرقه (منطقة الماتش = منطقة فرقه).
-- الماتشات القديمة/بتاعة الأدمن من غير منطقة = عامة لكل المناطق.

alter table public.teams enable row level security;
drop policy if exists "teams read" on public.teams;
create policy "teams read" on public.teams for select to authenticated using (true);
drop policy if exists "teams organizer insert" on public.teams;
create policy "teams organizer insert" on public.teams for insert to authenticated
  with check (public.is_organizer());
drop policy if exists "teams manager write" on public.teams;
create policy "teams manager write" on public.teams for update to authenticated
  using (public.is_manager()) with check (public.is_manager());
-- الحذف: الأدمن، أو الصاحب لو الفريق لسه ملوش لاعيبة ولا ماتشات
drop policy if exists "teams delete" on public.teams;
create policy "teams delete" on public.teams for delete to authenticated using (
  public.is_manager()
  or (owner_id = auth.uid()
      and not exists (select 1 from public.players pl where lower(trim(pl.team)) = lower(trim(teams.name)))
      and not exists (select 1 from public.matches m
                      where lower(trim(teams.name)) in (lower(trim(m.teams[1])), lower(trim(m.teams[2])))))
);

-- المنظّم: الفريق بيتسجّل باسمه وفي منطقته. الاسم مبيتغيّرش (هو المفتاح في اللاعيبة والماتشات).
create or replace function public.trg_teams_guard()
returns trigger language plpgsql as $$
declare z int;
begin
  new.name := trim(new.name);
  if tg_op = 'UPDATE' and new.name <> old.name then
    raise exception 'مينفعش تغيّر اسم الفريق — اعمل فريق جديد';
  end if;
  if current_user in ('authenticated', 'anon') and not public.is_manager() then
    if tg_op = 'INSERT' then
      select zone_id into z from public.profiles where id = auth.uid();
      if z is null then raise exception 'اختار منطقتك الأول'; end if;
      if (select count(*) from public.teams where owner_id = auth.uid()) >= 30 then
        raise exception 'آخرك ٣٠ فريق';
      end if;
      new.owner_id := auth.uid();
      new.zone_id := z;
    else
      new.owner_id := old.owner_id;
      new.zone_id := old.zone_id;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists teams_guard on public.teams;
create trigger teams_guard before insert or update on public.teams
for each row execute function public.trg_teams_guard();

-- الأدمن غيّر منطقة فريق → لاعيبته وماتشاته الجاية تتنقل معاه
create or replace function public.trg_teams_zone()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.zone_id is distinct from old.zone_id then
    update public.players set zone_id = new.zone_id where lower(trim(team)) = lower(trim(new.name));
    update public.matches set zone_id = new.zone_id
    where lower(trim(teams[1])) = lower(trim(new.name)) and status = 'upcoming';
  end if;
  return null;
end $$;
drop trigger if exists teams_zone on public.teams;
create trigger teams_zone after update on public.teams
for each row execute function public.trg_teams_zone();

-- ماتش جديد / ميعاده اتغيّر → إشعار لأهل منطقته (بدل ما التطبيق يبعته)
create or replace function public.trg_match_announce()
returns trigger language plpgsql security definer set search_path = public as $$
declare t text := to_char(new.date_time at time zone 'Africa/Cairo', 'DD/MM · HH12:MI');
begin
  if tg_op = 'INSERT' then
    perform public.fn_notify_match(new.id, 'ماتش جديد ⚽', new.teams[1] || ' ضد ' || new.teams[2] || ' · ' || t, 'match');
  elsif new.status = 'upcoming' and (new.date_time, new.teams) is distinct from (old.date_time, old.teams) then
    perform public.fn_notify_match(new.id, 'تعديل في ماتش 📝',
      new.teams[1] || ' ضد ' || new.teams[2] || ' · الميعاد الجديد ' || t, 'match');
  end if;
  return null;
end $$;
drop trigger if exists match_announce on public.matches;
create trigger match_announce after insert or update on public.matches
for each row execute function public.trg_match_announce();


-- ═══════════════════════════════════════════════════════════════
-- خلصنا. (اختياري) خلّي نفسك مدير — بدّل الإيميل بإيميلك:
--   update public.profiles set role = 'manager' where email = 'you@email.com';
-- الأدوار: user · organizer (منظّم ماتشات — الأدمن بيوافق على طلبه) · manager (الأدمن)
-- ═══════════════════════════════════════════════════════════════
