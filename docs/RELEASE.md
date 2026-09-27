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

- [ ] **الـ package name:** `com.example.fantasy_5omasi` مرفوض من Google Play. لازم يتغيّر، وتضيفه كأبلكيشن أندرويد جديد في Firebase.
- [ ] **Supabase على Pro** (عشان الباك أب اليومي وحدود الاتصالات).
- [ ] **Supabase ← Authentication:**
  - Confirm email.
  - Secure email change.
  - باسورد 8 حروف فيها حروف وأرقام.
  - Leaked password protection (موجودة في Pro).
- [ ] **ارفع `docs/privacy.html` و`docs/delete-account.html`**، مثلًا على GitHub Pages، وحط الروابط في `lib/core/app_links.dart` وفي صفحة المتجر. وبدّل `[إيميل التواصل]` بإيميل حقيقي.
- [ ] **الخرايط:** خوادم OpenStreetMap المجانية ممنوع استخدامها في أبلكيشن عليه ضغط كبير، واحتمال تتحظر. لازم مزوّد خرايط بمفتاح (MapTiler أو Stadia، وليهم باقة مجانية).
- [ ] **CAPTCHA على التسجيل** (Cloudflare Turnstile).
