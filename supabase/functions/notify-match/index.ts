// Supabase Edge Function: notify-match
// بتبعت إشعار FCM لكل المستخدمين إن تشكيلة ماتش نزلت.
// النشر: supabase functions deploy notify-match
// الأسرار المطلوبة:
//   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat service-account.json)"
// (SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY بيتوفّروا تلقائيًا)

import { createClient } from "jsr:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

Deno.serve(async (req) => {
  try {
    const { match_id } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // بيانات الماتش + توكنات المستخدمين
    const { data: match } = await supabase
      .from("matches").select("teams").eq("id", match_id).single();
    const teams: string[] = match?.teams ?? [];

    const { data: profiles } = await supabase
      .from("profiles").select("fcm_token").not("fcm_token", "is", null);
    const tokens: string[] = (profiles ?? []).map((p) => p.fcm_token).filter(Boolean);

    // OAuth token من service account
    const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
    const client = new JWT({
      email: sa.client_email,
      key: sa.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const { access_token } = await client.authorize();

    const title = "تشكيلة نزلت ⚽";
    const body = `${teams[0] ?? ""} ضد ${teams[1] ?? ""} — اختار تشكيلتك قبل الديدلاين`;

    let sent = 0;
    for (const token of tokens) {
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: { token, notification: { title, body } },
          }),
        },
      );
      if (res.ok) sent++;
    }

    return new Response(JSON.stringify({ sent }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
