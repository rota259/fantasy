// Supabase Edge Function: notify-match
// بتبعت إشعارات FCM:
//   • المدير: تشكيلة نزلت / أحداث / ماتش خلص / إشعار حر / تذكير.
//   • الحجز (booking_id): الحاجز ↔ صاحب الملعب — النص بيتكتب هنا مش من التطبيق.
// النشر: npx supabase functions deploy notify-match --project-ref <ref>
// الأسرار المطلوبة: FIREBASE_SERVICE_ACCOUNT
// (SUPABASE_URL و SUPABASE_SERVICE_ROLE_KEY بيتوفّروا تلقائيًا)

import { createClient } from "jsr:@supabase/supabase-js@2";
import { JWT } from "npm:google-auth-library@9";

const json = (o: unknown, status = 200) =>
  new Response(JSON.stringify(o), { status, headers: { "Content-Type": "application/json" } });

/// 21 → "9:00م" ، 24 → "12:00ص"
function fmtHour(h: number): string {
  const x = h % 24;
  const t = x === 0 ? 12 : x > 12 ? x - 12 : x;
  return `${t}:00${x < 12 ? "ص" : "م"}`;
}

Deno.serve(async (req) => {
  try {
    // كلهم اختياريين:
    //   match_id   → لو مفيش title/body نبعت "التشكيلة نزلت" بأسماء الفريقين.
    //   title/body → رسالة مخصّصة (أحداث / إشعار حر / تذكير).
    //   user_ids   → نبعت لليوزرز دول بس.
    //   booking_id → إشعار حجز (الطرف التاني في الحجز بيتحدّد أوتوماتيك).
    const { match_id, title: reqTitle, body: reqBody, user_ids, booking_id } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // مين اللي بيبعت؟
    const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    const { data: auth } = await supabase.auth.getUser(jwt);
    const callerId = auth.user?.id;
    if (!callerId) return json({ error: "unauthorized" }, 401);
    const { data: caller } = await supabase
      .from("profiles").select("role").eq("id", callerId).maybeSingle();
    const isManager = caller?.role === "manager";

    let title: string;
    let text: string;
    let targetIds: string[] | null; // null = للكل

    if (booking_id) {
      const { data: b } = await supabase
        .from("bookings").select("user_id, venue_id, status, day, hour").eq("id", booking_id).maybeSingle();
      if (!b) return json({ error: "booking not found" }, 404);
      const { data: v } = await supabase
        .from("venues").select("name, owner_id").eq("id", b.venue_id).maybeSingle();
      text = `${v?.name ?? ""} · ${b.day} · ${fmtHour(b.hour)}`;

      if (callerId === b.user_id && (b.status === "pending" || b.status === "cancelled")) {
        // الحاجز طلب أو لغى → نبلّغ صاحب الملعب
        if (!v?.owner_id) return json({ sent: 0, reason: "no owner" });
        targetIds = [v.owner_id];
        title = b.status === "pending" ? "طلب حجز جديد 📅" : "اتلغى حجز 🚫";
      } else if (isManager || (v?.owner_id && v.owner_id === callerId)) {
        // صاحب الملعب/المدير غيّر الحالة → نبلّغ الحاجز
        targetIds = [b.user_id];
        title = ({
          confirmed: "اتأكد حجزك ✅",
          rejected: "اترفض طلب الحجز ❌",
          cancelled: "اتلغى حجزك 🚫",
        } as Record<string, string>)[b.status] ?? "تحديث في حجزك";
      } else {
        return json({ error: "forbidden" }, 403);
      }
    } else {
      // باقي الإشعارات للمدير بس
      if (!isManager) return json({ error: "managers only" }, 403);
      let teams: string[] = [];
      if (match_id) {
        const { data: match } = await supabase
          .from("matches").select("teams").eq("id", match_id).maybeSingle();
        teams = match?.teams ?? [];
      }
      title = reqTitle ?? "تشكيلة نزلت ⚽";
      text = reqBody ?? `${teams[0] ?? ""} ضد ${teams[1] ?? ""} — اختار تشكيلتك قبل الديدلاين`;
      targetIds = Array.isArray(user_ids) && user_ids.length > 0 ? user_ids : null;
    }

    // التوكنات
    let query = supabase.from("profiles").select("fcm_token").not("fcm_token", "is", null);
    if (targetIds) query = query.in("id", targetIds);
    const { data: profiles } = await query;
    const tokens: string[] = (profiles ?? []).map((p) => p.fcm_token).filter(Boolean);
    if (tokens.length === 0) return json({ sent: 0, failed: 0, total: 0 });

    // OAuth token من service account
    const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
    const client = new JWT({
      email: sa.client_email,
      key: sa.private_key,
      scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
    });
    const { access_token } = await client.authorize();

    let sent = 0;
    let failed = 0;
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
            message: {
              token,
              notification: { title, body: text },
              android: { priority: "high" },
            },
          }),
        },
      );
      if (res.ok) sent++;
      else failed++;
    }

    return json({ sent, failed, total: tokens.length });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
