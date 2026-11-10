// Supabase Edge Function: auth-phone
// الدخول و«نسيت كلمة السر» برقم الموبايل — من غير ما إيميل الحساب يطلع من السيرفر أبدًا.
// (قبل كده الأبلكيشن كان بيسأل الداتابيز "إيميل الرقم ده إيه؟" وأي حد كان يقدر يسأل نفس السؤال.)
//
//   login          { phone, password }        → { access_token, refresh_token } أو { error }
//   reset          { phone }                  → { ok: true } دايمًا (مبنقولش الرقم متسجّل ولا لأ)
//   reset_confirm  { phone, code, password }  → { access_token, refresh_token } أو { error }
//
// الأخطاء: invalid · too_many · email_not_confirmed · weak_password · same_password · bad_code · captcha
// CAPTCHA: الأبلكيشن بيبعت captcha_token وإحنا بنعدّيه لـ Supabase Auth (gotrue_meta_security).
// الحماية من التخمين: phone_auth_email بتعدّ المحاولات لكل رقم (١٠ في ربع ساعة) + حدود Supabase Auth نفسها.
//
// النشر:  npx supabase functions deploy auth-phone --no-verify-jwt --project-ref <project-ref>
// السجلات: سطر JSON لكل طلب + أحداث الدخول (نجح · فشل · محاولات كتير) بالرقم متغطّي — _shared/log.ts
// الأسرار: مفيش — SUPABASE_URL و SUPABASE_ANON_KEY و SUPABASE_SERVICE_ROLE_KEY تلقائي جوه الفانكشن.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { makeLogger, maskPhone } from "../_shared/log.ts";

const URL_ = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const admin = createClient(URL_, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-request-id",
  "Access-Control-Expose-Headers": "X-Request-ID",
};
const json = (o: unknown) =>
  new Response(JSON.stringify(o), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

/** نداء Supabase Auth بمفتاح الأبلكيشن العادي (نفس اللي الموبايل بيستخدمه).
 *  [captcha] كود Turnstile من الأبلكيشن — Supabase بيتحقق منه لو الـ CAPTCHA مفعّلة. */
async function auth(path: string, body: Record<string, unknown>, method = "POST", bearer?: string, captcha?: string) {
  if (captcha) body = { ...body, gotrue_meta_security: { captcha_token: captcha } };
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
  const log = makeLogger("auth-phone", req, admin);
  try {
    return log.respond(await handle(req, log));
  } catch (e) {
    log.error("auth.unhandled", {}, e);
    return log.respond(json({ error: "invalid" }));
  }
});

async function handle(req: Request, log: ReturnType<typeof makeLogger>): Promise<Response> {
  {
    const b = await req.json();
    const phone = String(b.phone ?? "").trim();
    const password = String(b.password ?? "");
    const captcha = typeof b.captcha_token === "string" && b.captcha_token.length < 4000 ? b.captcha_token : undefined;
    if (phone.length < 6 || phone.length > 20 || phone.includes("@")) return json({ error: "invalid" });
    const who = { phone: maskPhone(phone), action: String(b.action ?? "") };
    const limited = () => (log.warn("auth.rate_limited", who), json({ error: "too_many" }));

    if (b.action === "login") {
      if (password.length < 1 || password.length > 200) return json({ error: "invalid" });
      const email = await emailFor(phone, 10);
      if (email === "too_many") return limited();
      if (!email) {
        await sleep(250 + Math.random() * 250); // نفس وقت المحاولة الحقيقية تقريبًا
        log.warn("auth.login.failed", { ...who, reason: "unknown_phone" });
        return json({ error: "invalid" });
      }
      const r = await auth("token?grant_type=password", { email, password }, "POST", undefined, captcha);
      if (r.ok && r.data.refresh_token) {
        log.info("auth.login.success", who);
        return json({ access_token: r.data.access_token, refresh_token: r.data.refresh_token });
      }
      const c = code(r.data).toLowerCase();
      if (c.includes("not_confirmed") || c.includes("not confirmed")) return json({ error: "email_not_confirmed" });
      if (c.includes("captcha")) {
        log.warn("auth.captcha.rejected", who);
        return json({ error: "captcha" });
      }
      if (r.status === 429) return limited();
      log.warn("auth.login.failed", { ...who, reason: "bad_password" });
      return json({ error: "invalid" });
    }

    if (b.action === "reset") {
      const email = await emailFor(phone, 4);
      if (email && email !== "too_many") await auth("recover", { email }, "POST", undefined, captcha);
      else await sleep(250 + Math.random() * 250);
      log.info("auth.password_reset.requested", { ...who, sent: !!email && email !== "too_many" });
      return json({ ok: true }); // دايمًا نفس الرد
    }

    if (b.action === "reset_confirm") {
      const token = String(b.code ?? "").trim();
      if (!/^\d{6}$/.test(token) || password.length < 8 || password.length > 200) return json({ error: "bad_code" });
      const email = await emailFor(phone, 10);
      if (email === "too_many") return limited();
      if (!email) return json({ error: "bad_code" });
      const v = await auth("verify", { type: "recovery", email, token }, "POST", undefined, captcha);
      if (!v.ok || !v.data.access_token) {
        log.warn("auth.password_reset.failed", { ...who, reason: v.status === 429 ? "too_many" : "bad_code" });
        return json({ error: v.status === 429 ? "too_many" : "bad_code" });
      }
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
      log.info("auth.password_reset.done", who);
      return json({ access_token: v.data.access_token, refresh_token: v.data.refresh_token });
    }

    return json({ error: "invalid" });
  }
}
