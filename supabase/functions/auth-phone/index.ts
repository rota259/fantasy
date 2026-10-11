// Supabase Edge Function: auth-phone
// الدخول و«نسيت كلمة السر» برقم الموبايل — من غير ما إيميل الحساب يطلع من السيرفر أبدًا.
// (قبل كده الأبلكيشن كان بيسأل الداتابيز "إيميل الرقم ده إيه؟" وأي حد كان يقدر يسأل نفس السؤال.)
//
//   login          { phone, password }        → { access_token, refresh_token } أو { error }
//   reset          { phone }                  → { ok: true } دايمًا (مبنقولش الرقم متسجّل ولا لأ)
//   reset_confirm  { phone, code, password }  → { access_token, refresh_token } أو { error }
//
// الأخطاء: invalid · too_many · email_not_confirmed · weak_password · same_password · bad_code
// الحماية من التخمين: phone_auth_email بتعدّ المحاولات لكل رقم (١٠ في ربع ساعة) + حدود Supabase Auth نفسها.
//
// النشر:  npx supabase functions deploy auth-phone --no-verify-jwt --project-ref <project-ref>
// الأسرار: مفيش — SUPABASE_URL و SUPABASE_ANON_KEY و SUPABASE_SERVICE_ROLE_KEY تلقائي جوه الفانكشن.

import { createClient } from "jsr:@supabase/supabase-js@2";

const URL_ = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(URL_, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (o: unknown) =>
  new Response(JSON.stringify(o), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** نداء Supabase Auth بمفتاح الأبلكيشن العادي (نفس اللي الموبايل بيستخدمه). */
async function auth(path: string, body: unknown, method = "POST", bearer?: string) {
  const res = await fetch(`${URL_}/auth/v1/${path}`, {
    method,
    headers: { apikey: ANON, Authorization: `Bearer ${bearer ?? ANON}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  let data: Record<string, unknown> = {};
  try {
    data = await res.json();
  } catch (_) { /* رد فاضي */ }
  return { ok: res.ok, status: res.status, data };
}

/** إيميل الرقم (جوه السيرفر بس) — null لو مش متسجّل، و"too_many" لو المحاولات كترت. */
async function emailFor(phone: string, max: number): Promise<string | null | "too_many"> {
  const { data, error } = await admin.rpc("phone_auth_email", { p: phone, p_max: max });
  if (error) return error.message.includes("too_many") ? "too_many" : null;
  return (data as string | null) || null;
}

const code = (d: Record<string, unknown>) => String(d.error_code ?? d.code ?? d.msg ?? d.error_description ?? "");

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const b = await req.json();
    const phone = String(b.phone ?? "").trim();
    const password = String(b.password ?? "");
    if (phone.length < 6 || phone.length > 20 || phone.includes("@")) return json({ error: "invalid" });

    if (b.action === "login") {
      if (password.length < 1 || password.length > 200) return json({ error: "invalid" });
      const email = await emailFor(phone, 10);
      if (email === "too_many") return json({ error: "too_many" });
      if (!email) {
        await sleep(250 + Math.random() * 250); // نفس وقت المحاولة الحقيقية تقريبًا
        return json({ error: "invalid" });
      }
      const r = await auth("token?grant_type=password", { email, password });
      if (r.ok && r.data.refresh_token) {
        return json({ access_token: r.data.access_token, refresh_token: r.data.refresh_token });
      }
      const c = code(r.data).toLowerCase();
      if (c.includes("not_confirmed") || c.includes("not confirmed")) return json({ error: "email_not_confirmed" });
      if (r.status === 429) return json({ error: "too_many" });
      return json({ error: "invalid" });
    }

    if (b.action === "reset") {
      const email = await emailFor(phone, 4);
      if (email && email !== "too_many") await auth("recover", { email });
      else await sleep(250 + Math.random() * 250);
      return json({ ok: true }); // دايمًا نفس الرد
    }

    if (b.action === "reset_confirm") {
      const token = String(b.code ?? "").trim();
      if (!/^\d{6}$/.test(token) || password.length < 8 || password.length > 200) return json({ error: "bad_code" });
      const email = await emailFor(phone, 10);
      if (email === "too_many") return json({ error: "too_many" });
      if (!email) return json({ error: "bad_code" });
      const v = await auth("verify", { type: "recovery", email, token });
      if (!v.ok || !v.data.access_token) return json({ error: v.status === 429 ? "too_many" : "bad_code" });
      const u = await auth("user", { password }, "PUT", String(v.data.access_token));
      if (!u.ok) {
        const c = code(u.data).toLowerCase();
        // الكود اتستهلك بس كلمة السر مرفوضة: نرجّع الجلسة عشان الأبلكيشن يكمّل التغيير من غير كود جديد
        return json({
          error: c.includes("same") ? "same_password" : "weak_password",
          access_token: v.data.access_token,
          refresh_token: v.data.refresh_token,
        });
      }
      return json({ access_token: v.data.access_token, refresh_token: v.data.refresh_token });
    }

    return json({ error: "invalid" });
  } catch (_) {
    return json({ error: "invalid" });
  }
});
