# نزول «الخماسي» على المتاجر

## ١) مفتاح توقيع أندرويد (مرة واحدة — واحفظه كويس)

المفتاح ده هو هوية الأبلكيشن على Google Play. لو ضاع، مش هتقدر تنزّل تحديث تاني بنفس الأبلكيشن.
احفظ ملف `.jks` وكلمات السر في مكانين آمنين، زي password manager وفلاشة. **متبعتهمش لحد، ومتحطهمش على git.**

```bash
keytool -genkey -v -keystore %USERPROFILE%\khomasi-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias khomasi
```

اعمل الملف `android/key.properties` (هو في `.gitignore` أصلًا):

```properties
storePassword=كلمة سر الـ keystore
keyPassword=كلمة سر المفتاح
keyAlias=khomasi
storeFile=C:/Users/AMR/khomasi-release.jks
```

## ٢) البناء (مع تشويش الكود)

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
flutter build ipa --release --obfuscate --split-debug-info=build/debug-info
```

ملفات `build/debug-info` بتحتاجها عشان تقرا أي crash، فاحفظها مع كل إصدار.

## ٣) Google Play — Data safety

| السؤال | الإجابة |
|---|---|
| بتجمع بيانات؟ | أيوه |
| بتشارك بيانات مع جهات تانية؟ | لأ (Supabase وFirebase مقدّمي خدمة لينا، مش "مشاركة") |
| البيانات مشفّرة وهي بتتنقل؟ | أيوه |
| اليوزر يقدر يطلب حذف بياناته؟ | أيوه — من التطبيق + رابط `delete-account.html` |
| **Personal info:** Name, Email, Phone number | Collected · App functionality, Account management · Required |
| **Photos** | Collected · App functionality · Optional (صورة البروفايل) |
| **App activity:** In-app actions | Collected · App functionality |
| **Device IDs:** (push token) | Collected · App functionality (الإشعارات) |
| **App info and performance:** Crash logs, Diagnostics | Collected · Analytics (تصليح الأعطال) · مرتبطة بالحساب · بتتمسح بعد ٣٠ يوم |
| **Location** | مش بنجمعه (المنطقة اليوزر بيختارها بنفسه) |

- رابط سياسة الخصوصية: `privacy.html`
- رابط حذف الحساب: `delete-account.html`

## ٤) App Store — App Privacy

- **Contact Info** (Name, Email, Phone): Linked to user · App Functionality.
- **User Content** (Photos, Other: تقييمات): Linked · App Functionality.
- **Usage Data** (Product Interaction): Linked · App Functionality.
- **Identifiers** (Device ID للإشعارات): Linked · App Functionality.
- مفيش Tracking.

## ٥) قبل ما تدوس "نشر"

- [ ] **وضع التجربة مقفول:** `kTestMode` في `lib/core/app_mode.dart` و`fn_test_mode()` في `supabase/migrate_all.sql` الاتنين `false`.
- [ ] **قاعدة البيانات متحدّثة:** `supabase/migrate_all.sql` اتشغّل على المشروع الأصلي بعد آخر تعديل، وبعده `supabase/reset_data.sql` لمسح داتا التجربة.
- [ ] **الـ Edge Functions منشورة:** `push` و`auth-phone`، والسر `FIREBASE_SERVICE_ACCOUNT` متسجّل.
- [ ] **السجلات شغّالة:** افتح لوحة الأدمن ← «السجلات والأخطاء» واتأكد إن نبض السيرفر أخضر، وجرّب الاختبار اللي في `docs/LOGGING.md`. وحط السر `APP_ENV` و`LOG_LEVEL` للـ Edge Functions لو عايز تغيّر الافتراضي.
- [ ] **الاختبارات عدّت:** `flutter analyze` و`flutter test` و`cd supabase/tests && npm test`.
- [ ] **رقم الإصدار زاد** في `pubspec.yaml` (الرقم اللي بعد `+`).
- [ ] **الدخول بجوجل:** بصمة SHA-1 بتاعة مفتاح المتجر (وبتاعة Play App Signing) متضافة في Firebase وGoogle Cloud، وإلا الدخول بجوجل هيفشل في النسخة المنشورة.
- [ ] **الجلسة المشفّرة:** على الموبايل: ادخل · اقفل الأبلكيشن خالص وافتحه · اعمل restart للموبايل وافتحه — لازم تفضل داخل في التلاتة. ولو كنت داخل بنسخة قديمة قبل التحديث، لازم تفضل داخل بعده.
- [ ] **جرّبت نسخة الـ release على موبايل حقيقي** قبل الرفع: `flutter run --release`.
- [ ] **الـ package name:** `com.example.fantasy_5omasi` مرفوض من Google Play. لازم يتغيّر، وتضيفه كأبلكيشن أندرويد جديد في Firebase.
- [ ] **Supabase على Pro** (عشان الباك أب اليومي وحدود الاتصالات).
- [ ] **Supabase ← Authentication:**
  - Confirm email.
  - Secure email change.
  - باسورد 8 حروف فيها حروف وأرقام.
  - Leaked password protection (موجودة في Pro).
- [ ] **ارفع `docs/privacy.html` و`docs/delete-account.html`**، مثلًا على GitHub Pages، وحط الروابط في `lib/core/app_links.dart` وفي صفحة المتجر. وبدّل `[إيميل التواصل]` بإيميل حقيقي.
- [ ] **CAPTCHA:** Secret key في Supabase + البناء بـ `--dart-define=TURNSTILE_SITE_KEY=...` (الاتنين مع بعض — `supabase/AUTH_SETUP.md` قسم 7).

## الحماية وقت التشغيل (freeRASP) — `lib/core/security/rasp.dart`
- [ ] **بصمة مفتاح جوجل بلاي:** من Play Console ← Setup ← App signing ← SHA-256 للـ App signing key (ولـ Upload key). حوّل كل واحدة لـ base64 (`python -c "import base64;print(base64.b64encode(bytes.fromhex('AABB...')).decode())"`) وابني بـ `--dart-define=RASP_CERT_HASHES=hash1,hash2`. لحد ما ده يتعمل، كشف التلاعب بيسجّل بس ومش بيقفل.
- [ ] (اختياري) `--dart-define=RASP_MAIL=...` إيميل يوصله تقرير الأمان الأسبوعي من Talsec.
- القفل الفعلي: Frida/hooks دايمًا، والـ debugger في نسخة الإصدار. الروت والمحاكي والتلاعب والمتجر: تسجيل في السجلات (`security.threat`) بس.
- البناء: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` (احتفظ بـ `build/symbols` عشان تقرا الأعطال).

## قبل النشر للكل
- [ ] **اسم الباكدج:** `com.example.*` مرفوض في جوجل بلاي ومبيتغيّرش بعد أول رفع. اختار اسم ← ضيف تطبيق أندرويد بنفس الاسم في فايربيز (khomasi-e383e) ← نزّل `google-services.json` الجديد ← غيّر `applicationId` و`Rasp._pkg`.
- [ ] **الحساب الشخصي الجديد:** Closed testing بـ ١٢ مختبِر لمدة ١٤ يوم قبل الإنتاج — ابدأه بدري، واستغله كجولة تجريبية حقيقية في بدر.
- [ ] **Supabase Pro** من يوم الإطلاق (الخطة المجانية بتقف لو مفيش حركة أسبوع، ومفيش نسخ احتياطي لأي لحظة).
- [ ] **مشرفين مناطق:** من «إدارة اليوزرز» ← «مشرف» — عشان اعتماد الماتشات ميستناش الأدمن لوحده.
