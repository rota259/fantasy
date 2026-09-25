// Supabase Edge Function: push
// أي صف بيتسجّل في notifications → الداتابيز بتنادي الفنكشن دي (pg_net) بـ id الإشعار + سر.
// بتبعت FCM حسب الجمهور:
//   all   → topic "all" (كل الأجهزة مشتركة فيه) — طلب واحد مهما كان عدد اليوزرز
//   user  → توكن اليوزر
//   match → توكنات متابعين الماتش
// النشر:  npx supabase functions deploy push --no-verify-jwt --project-ref jhofyglkpwguzodbeyia
// السر المطلوب: FIREBASE_SERVICE_ACCOUNT  (SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY تلقائي)

import { createClient } from "jsr:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "Content-Type": "application/json" } });

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");
const jwt = new JWT({
  email: sa.client_email,
  key: sa.private_key,
  scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
});

type Target = { token: string } | { topic: string };

async function send(target: Target, n: Record<string, string>, accessToken: string) {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: "POST",
    headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      message: {
        ...target,
        notification: { title: n.title, body: n.body },
        data: { kind: n.kind, match_id: n.match_id ?? "" },
        android: { priority: "high", notification: { sound: "default" } },
        apns: { payload: { aps: { sound: "default" } } },
      },
    }),
  });
  return res;
}

Deno.serve(async (req) => {
  try {
    const { id, secret } = await req.json();
    if (!id || !secret) return json({ error: "bad request" }, 400);

    // الطلب لازم يكون جاي من الداتابيز
    const { data: ok } = await supabase.rpc("push_secret_ok", { s: secret });
    if (ok !== true) return json({ error: "forbidden" }, 403);

    const { data: n } = await supabase
      .from("notifications").select("title, body, kind, audience, user_id, match_id")
      .eq("id", id).maybeSingle();
    if (!n) return json({ error: "not found" }, 404);

    const { access_token } = await jwt.authorize();
    if (!access_token) return json({ error: "fcm auth failed" }, 500);

    if (n.audience === "all") {
      const res = await send({ topic: "all" }, n, access_token);
      return json({ topic: "all", ok: res.ok });
    }

    // توكنات الجمهور المحدّد
    let tokens: { id: string; fcm_token: string }[] = [];
    if (n.audience === "user" && n.user_id) {
      const { data } = await supabase.from("profiles").select("id, fcm_token")
        .eq("id", n.user_id).not("fcm_token", "is", null);
      tokens = data ?? [];
    } else if (n.audience === "match" && n.match_id) {
      const { data: follows } = await supabase.from("match_follows").select("user_id").eq("match_id", n.match_id);
      const ids = (follows ?? []).map((f) => f.user_id);
      if (ids.length > 0) {
        const { data } = await supabase.from("profiles").select("id, fcm_token")
          .in("id", ids).not("fcm_token", "is", null);
        tokens = data ?? [];
      }
    }

    let sent = 0;
    for (const t of tokens) {
      const res = await send({ token: t.fcm_token }, n, access_token);
      if (res.ok) {
        sent++;
      } else if (res.status === 404 || res.status === 400) {
        // التوكن مبقاش صالح (الأبلكيشن اتمسح مثلًا) → نشيله
        await supabase.from("profiles").update({ fcm_token: null }).eq("id", t.id);
      }
    }
    return json({ sent, total: tokens.length });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
