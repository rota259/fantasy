// الـ logger المشترك للـ Edge Functions — سطر JSON لكل حدث على stdout (Supabase بيجمعه في Logs → Edge Functions).
// التحذيرات والأخطاء بتتسجّل كمان في السجل المركزي (جدول app_logs) عن طريق fn_log.
//
//   const log = makeLogger("auth-phone", req, admin);
//   log.info("auth.login.success");
//   log.error("push.fcm.failed", { status: 500 }, err);
//   return log.respond(json({...}));     ← بيرجّع X-Request-ID وبيسجّل سطر الطلب (الكود والمدة)
//
// ممنوع يتسجّل: كلمة السر · الكود · التوكنات · الإيميل · محتوى الطلب. الرقم بيتغطّى بـ maskPhone.
// المستوى: السر LOG_LEVEL (debug · info · warn · error) — الافتراضي info.

// deno-lint-ignore-file no-explicit-any
const LEVELS = ["debug", "info", "warn", "error", "fatal"] as const;
type Level = (typeof LEVELS)[number];

const wanted = LEVELS.indexOf((Deno.env.get("LOG_LEVEL") ?? "info").toLowerCase() as Level);
const MIN = wanted < 0 ? 1 : wanted; // قيمة غلط = info
const ENV = Deno.env.get("APP_ENV") ?? "prod";
const VERSION = Deno.env.get("SB_EXECUTION_ID") ?? Deno.env.get("DENO_DEPLOYMENT_ID") ?? "unknown";
const SECRET = /(pass|token|secret|api_?key|authorization|cookie|otp|^code$|card|cvv)/i;

/** 010*****78 — الرقم في السجل للتمييز بس، مش للقراية. */
export const maskPhone = (p: string) => (p.length < 6 ? "***" : `${p.slice(0, 3)}*****${p.slice(-2)}`);

function clean(fields: Record<string, unknown> = {}) {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(fields)) {
    if (SECRET.test(k)) continue;
    out[k] = typeof v === "string" ? v.slice(0, 300) : (typeof v === "number" || typeof v === "boolean" ? v : String(v));
  }
  return out;
}

export function makeLogger(service: string, req: Request, db?: { rpc: (fn: string, args: any) => any }) {
  const incoming = req.headers.get("x-request-id") ?? "";
  const requestId = /^[A-Za-z0-9_-]{6,64}$/.test(incoming) ? incoming : `req_${crypto.randomUUID().slice(0, 16)}`;
  const started = Date.now();
  const route = `${req.method} /functions/v1/${service}`;

  function write(level: Level, event: string, fields?: Record<string, unknown>, err?: unknown) {
    if (LEVELS.indexOf(level) < MIN) return;
    const e = err instanceof Error ? err : err === undefined ? null : new Error(String(err));
    const line = {
      timestamp: new Date().toISOString(), // UTC بالملّي ثانية
      level,
      service: `edge:${service}`,
      env: ENV,
      version: VERSION,
      event,
      request_id: requestId,
      ...clean(fields),
      ...(e ? { error_type: e.name, error_stack: (e.stack ?? e.message).slice(0, 4000) } : {}),
    };
    (level === "error" || level === "fatal" ? console.error : console.log)(JSON.stringify(line));
    // المهم بيروح السجل المركزي كمان (من غير ما نستنّاه ولا نوقّع الطلب لو فشل)
    if (db && LEVELS.indexOf(level) >= 2) {
      Promise.resolve(db.rpc("fn_log", {
        p_level: level,
        p_event: event,
        p_message: e ? e.message.slice(0, 300) : null,
        p_fields: { ...clean(fields), ...(e ? { error_type: e.name } : {}) },
        p_service: `edge:${service}`,
        p_request_id: requestId,
      })).catch(() => {});
    }
  }

  return {
    requestId,
    debug: (event: string, f?: Record<string, unknown>) => write("debug", event, f),
    info: (event: string, f?: Record<string, unknown>) => write("info", event, f),
    warn: (event: string, f?: Record<string, unknown>, err?: unknown) => write("warn", event, f, err),
    error: (event: string, f?: Record<string, unknown>, err?: unknown) => write("error", event, f, err),
    /** سطر الطلب (الكود والمدة) + رقم الطلب في الرد. */
    respond(res: Response, outcome?: string) {
      const status = res.status;
      write(status >= 500 ? "error" : "info", "http.request", {
        route,
        status,
        duration_ms: Date.now() - started,
        ...(outcome ? { outcome } : {}),
      });
      res.headers.set("X-Request-ID", requestId);
      return res;
    },
  };
}
