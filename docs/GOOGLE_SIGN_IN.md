# الدخول بجوجل — الإعداد (مجاني)

الكود جاهز. الزرار بيظهر أول ما `GOOGLE_WEB_CLIENT_ID` يتحط.

## ١) Google Cloud Console

1. ادخل <https://console.cloud.google.com> واعمل مشروع جديد (مثلًا `khomasi`).
2. **APIs & Services ← OAuth consent screen**:
   - External، اسم التطبيق «الخماسي»، وإيميل الدعم.
   - الصلاحيات (Scopes): **email** و **profile** بس. دول عاديين ومش محتاجين مراجعة من جوجل.
   - بعد ما تخلص دوس **Publish app**، عشان أي حد يقدر يدخل مش حسابات التجربة بس.
3. **Credentials ← Create credentials ← OAuth client ID** — اعمل اتنين:
   - **Web application** (ده اللي Supabase بيستخدمه):
     - Authorized redirect URIs:
       - `https://jhofyglkpwguzodbeyia.supabase.co/auth/v1/callback`
       - `https://tnziqngtcxrufskdesod.supabase.co/auth/v1/callback`
     - انسخ **Client ID** و **Client secret**.
   - **Android**:
     - Package name: `com.example.fantasy_5omasi` (لو اتغيّر بعدين، اعمل Android client جديد).
     - SHA-1 بتاع جهازك للتجربة:
       ```bash
       keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
       ```
     - ولما تعمل مفتاح المتجر، ضيف الـ SHA-1 بتاعه كمان، والـ SHA-1 اللي Google Play بيدّيهولك.

## ٢) Supabase (المشروعين)

**Authentication ← Sign In / Providers ← Google** ← Enable:
- **Client IDs**: الـ Web Client ID.
- **Client Secret**: الـ secret. ده سر، فبتحطه انت هنا بنفسك ومتبعتهوش لحد.

## ٣) ابعتلي

**الـ Web Client ID بس.** شكله `xxxx.apps.googleusercontent.com`، وده مش سر. هحطه في الكود، أو شغّل مؤقتًا:

```bash
flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
```

## ملاحظات

- اليوزر الجديد بجوجل بيتعمله حساب لوحده، وبيختار منطقته أول مرة (رقم الموبايل اختياري).
- لو حد عنده حساب بإيميل وباسورد ودخل بجوجل بنفس الإيميل، Supabase بيربطهم في حساب واحد.
- **آبل:** محتاجة حساب Apple Developer (99$ في السنة)، ومتأجّلة.
- **iOS:** محتاج iOS client ID كمان. هنعمله لما نجهّز نسخة آيفون.
