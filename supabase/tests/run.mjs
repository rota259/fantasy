// بيشغّل migrate_all.sql على Postgres فاضي (PGlite) مرتين (مشروع جديد + إعادة تشغيل)، وبعدين اختبار جولة كاملة.
// التشغيل: cd supabase/tests && npm install && npm test
import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';

const here = new URL('.', import.meta.url);
const stubs = readFileSync(new URL('stubs.sql', here), 'utf8');
// الاختبارات بتختبر القوانين الحقيقية (وضع التجربة مقفول) — إلا مع --test-mode
const testMode = process.argv.includes('--test-mode');
const flag = `select ${testMode}; $$;  -- TEST_MODE`;
const migration = readFileSync(process.argv[2], 'utf8').replace('select true; $$;  -- TEST_MODE', () => flag);
const extra = process.argv[3] ? readFileSync(process.argv[3], 'utf8') : null;

const db = new PGlite();
await db.exec(stubs);

async function run(label, sql) {
  const t = Date.now();
  try {
    await db.exec(sql);
    console.log(`✓ ${label} (${Date.now() - t}ms)`);
  } catch (e) {
    console.log(`✗ ${label}: ${e.message}`);
    if (e.position) {
      const pos = Number(e.position);
      console.log('--- near ---\n' + sql.slice(Math.max(0, pos - 300), pos + 200));
    }
    if (e.where) console.log('where:', e.where);
    process.exit(1);
  }
}

await run('fresh database', migration);
await run('re-run (idempotent)', migration);
if (extra) await run('smoke tests', extra);
const r = await db.query("select count(*)::int as n from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public'");
console.log('public functions:', r.rows[0].n);
