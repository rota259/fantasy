# تأكيد الإيميل بالكود + نسيت كلمة السر — إعدادات Supabase

الكود في الأبلكيشن جاهز، بس مش هيشتغل غير لما تتعمل الإعدادات دي في لوحة Supabase.
**اعملها في المشروعين: التجربة (staging) والأساسي (prod).**

## ١) شغّل تأكيد الإيميل
Authentication → Sign In / Providers → **Email**:
- **Confirm email** = ON
- **Email OTP Expiration** = `600` (١٠ دقايق)
- **Email OTP Length** = `6`
- **Minimum password length** = `8` · Password requirements = letters and digits
- **Secure email change** = ON

## ٢) خلّي الرسالة تبعت كود مش لينك
Authentication → Emails → Templates — عدّل القالبين دول:

**Confirm signup** (Subject: `كود تأكيد حسابك في الخماسي`)
```html
<h2>أهلاً بيك في الخماسي ⚽</h2>
<p>كود تأكيد إيميلك:</p>
<h1 style="letter-spacing:6px">{{ .Token }}</h1>
<p>الكود صالح ١٠ دقايق. لو مش إنت اللي طلبته تجاهل الرسالة دي.</p>
```

**Reset password** (Subject: `كود تغيير كلمة السر — الخماسي`)
```html
<h2>تغيير كلمة السر</h2>
<p>الكود بتاعك:</p>
<h1 style="letter-spacing:6px">{{ .Token }}</h1>
<p>الكود صالح ١٠ دقايق. لو مش إنت اللي طلبته تجاهل الرسالة دي ومتديش الكود لحد.</p>
```

المهم يبقى فيه `{{ .Token }}` — ده الكود. شيل `{{ .ConfirmationURL }}` عشان مايبقاش فيه لينك.

## ٣) SMTP بتاعك (ضروري)
الإرسال الافتراضي بتاع Supabase بيبعت لإيميلات فريق المشروع بس وبعدد قليل جدًا في الساعة — يعني اليوزرز مش هيوصلهم حاجة.

Authentication → Emails → **SMTP Settings** → Enable Custom SMTP:

| | Gmail | Resend / Brevo (أحسن للإنتاج) |
|---|---|---|
| Host | `smtp.gmail.com` | من لوحة الخدمة |
| Port | `465` | `465` |
| Username | إيميل الجيميل | من لوحة الخدمة |
| Password | **App Password** من حساب جوجل (لازم التحقق بخطوتين) | API key |
| الحد | ~٥٠٠ رسالة في اليوم | ٣٠٠ في اليوم مجانًا (Brevo) |

الباسورد ده بتكتبه إنت في لوحة Supabase بس — متبعتوش لأي حد ولا تحطه في الكود.

## ٤) حدود الإرسال
Authentication → **Rate Limits**:
- Emails sent per hour: ارفعها (مثلًا `100`) بعد ما تحط الـ SMTP
- Token verifications: سيبها زي ما هي (بتمنع تخمين الكود)

## ٥) جرّب
1. اعمل حساب جديد بإيميل حقيقي → المفروض تتفتح شاشة الكود ويوصلك إيميل.
2. اكتب كود غلط → «الكود غلط أو انتهى».
3. سجّل خروج → «نسيت كلمة السر؟» → كود → كلمة سر جديدة → دخول.

الحسابات القديمة (اللي اتعملت قبل تفعيل التأكيد) وحسابات جوجل متأكّدة أصلًا ومش هتتأثر.

## ٦) الدخول برقم الموبايل (فانكشن auth-phone)
الدخول و«نسيت كلمة السر» برقم الموبايل بقوا بيتعملوا في السيرفر عشان إيميل الحساب ميطلعش بره.
**الترتيب مهم — الفانكشن الأول وبعدين ملف الداتابيز:**

```bash
npx supabase functions deploy auth-phone --no-verify-jwt --project-ref tnziqngtcxrufskdesod
```
```bash
npx supabase functions deploy auth-phone --no-verify-jwt --project-ref jhofyglkpwguzodbeyia
```

وبعدها شغّل `supabase/migrate_all.sql` (قسم 44 بيقفل الدالة القديمة). مفيش أسرار محتاجة تتحط للفانكشن دي.
لو شغّلت ملف الداتابيز قبل ما تنشر الفانكشن، الدخول بالرقم هيقف لحد ما تنشرها (الدخول بالإيميل وجوجل شغالين عادي).
