// اختبار ضغط على مشروع Supabase (الـ staging بس — متشغّلوش على الأصلي وفيه ناس).
// بيعمل [VUS] يوزر وهمي في نفس الوقت، كل واحد بيكرر طلبات الأبلكيشن لمدة [SECONDS] ثانية،
// وبيطلع: عدد الطلبات في الثانية · السرعة (p50 · p95 · p99) · الأخطاء لكل طلب.
//
// التشغيل (من جذر المشروع):
//   node tool/load_test.mjs                              ← طلبات الزائر بس (المناطق · إعدادات الأبلكيشن)
//   ACCESS_TOKEN=<توكن يوزر تجربة> node tool/load_test.mjs ← + طلبات اليوزر المسجّل (الرئيسية · الدوري · التشكيلة)
// المتغيرات: SUPABASE_URL · SUPABASE_KEY (لو مش متحددين بيتقروا من supabase_keys.dart: staging) · VUS · SECONDS
// التوكن: من الأبلكيشن على الـ staging بعد الدخول (مفيش حد غيرك يحطه — ومتحطوش في git).
import { readFileSync } from 'node:fs';

const keys = readFileSync(new URL('../lib/core/supabase/supabase_keys.dart', import.meta.url), 'utf8');
const pick = (name) => keys.match(new RegExp(`${name} = '([^']+)'`))?.[1];
const URL_ = process.env.SUPABASE_URL ?? pick('stagingUrl');
const KEY = process.env.SUPABASE_KEY ?? pick('stagingAnonKey');
const TOKEN = process.env.ACCESS_TOKEN;
const VUS = Number(process.env.VUS ?? 30);
const SECONDS = Number(process.env.SECONDS ?? 30);
if (!URL_ || !KEY) throw new Error('مفيش URL أو مفتاح');
if (URL_.includes('jhofyglkpwguzodbeyia') && !process.env.I_KNOW_THIS_IS_PROD) {
  throw new Error('ده المشروع الأصلي — الاختبار على الـ staging بس (أو I_KNOW_THIS_IS_PROD=1)');
}

const auth = TOKEN ?? KEY;
const headers = { apikey: KEY, Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json' };
const anon = [
  ['zones', () => fetch(`${URL_}/rest/v1/zones?select=id,name,governorate&order=sort`, { headers })],
  ['app_config', () => fetch(`${URL_}/rest/v1/rpc/get_app_config`, { method: 'POST', headers, body: '{}' })],
];
const user = [
  ['my_profile', () => fetch(`${URL_}/rest/v1/rpc/my_profile`, { method: 'POST', headers, body: '{}' })],
  ['global_rank', () => fetch(`${URL_}/rest/v1/rpc/my_global_rank`, { method: 'POST', headers, body: '{}' })],
  ['matches', () => fetch(`${URL_}/rest/v1/matches?select=*&order=date_time.desc&limit=30`, { headers })],
  ['players', () => fetch(`${URL_}/rest/v1/players?select=*&limit=200`, { headers })],
  ['notifications', () => fetch(`${URL_}/rest/v1/notifications?select=*&order=created_at.desc&limit=30`, { headers })],
];
const scenario = TOKEN ? [...anon, ...user] : anon;

const stats = new Map(scenario.map(([n]) => [n, { ms: [], errors: 0, codes: {} }]));
const end = Date.now() + SECONDS * 1000;

async function vu() {
  while (Date.now() < end) {
    for (const [name, call] of scenario) {
      const s = stats.get(name);
      const t = performance.now();
      try {
        const res = await call();
        await res.arrayBuffer();
        s.codes[res.status] = (s.codes[res.status] ?? 0) + 1;
        if (!res.ok) s.errors++;
      } catch {
        s.errors++;
        s.codes.network = (s.codes.network ?? 0) + 1;
      }
      s.ms.push(performance.now() - t);
    }
  }
}

const pct = (a, p) => (a.length ? a[Math.min(a.length - 1, Math.floor((p / 100) * a.length))] : 0).toFixed(0);
console.log(`${URL_} · ${VUS} يوزر في نفس الوقت · ${SECONDS} ثانية · ${TOKEN ? 'زائر + يوزر مسجّل' : 'زائر بس'}`);
const started = Date.now();
await Promise.all(Array.from({ length: VUS }, vu));
const took = (Date.now() - started) / 1000;
let total = 0;
for (const [name, s] of stats) {
  s.ms.sort((a, b) => a - b);
  total += s.ms.length;
  console.log(
    `${name.padEnd(14)} ${String(s.ms.length).padStart(6)} طلب · p50 ${pct(s.ms, 50)}ms · p95 ${pct(s.ms, 95)}ms · ` +
      `p99 ${pct(s.ms, 99)}ms · أخطاء ${s.errors} · ${JSON.stringify(s.codes)}`,
  );
}
console.log(`الإجمالي ${total} طلب في ${took.toFixed(1)} ثانية = ${(total / took).toFixed(0)} طلب/ثانية`);
