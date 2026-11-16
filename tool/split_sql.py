"""يقسّم supabase/migrate_all.sql لملفات صغيرة (supabase/parts/) عشان محرر Supabase يقدر يحفظها.

الملف الكبير (+٥٠٠ كيلو) بيشتغل في المحرر بس مبيتحفظش. التقسيم على حدود الأقسام بس (سطور «-- ═══» و«-- ╔»)،
فمفيش دالة بتتقسم نصّين. شغّل الأجزاء بالترتيب 01 → آخر واحد، ونتيجتها نفس نتيجة الملف الكبير.

التشغيل (من فولدر المشروع):  python tool/split_sql.py
الملف الكبير هو الأصل — أي تعديل فيه وبعدين شغّل السكربت ده تاني.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'supabase' / 'migrate_all.sql'
OUT = ROOT / 'supabase' / 'parts'
LIMIT = 90_000  # بايت لكل جزء — تحت حد الحفظ في المحرر بهامش

lines = SRC.read_text(encoding='utf-8').splitlines(keepends=True)
header = re.compile(r'^-- (═══ |╔)')

# الأقسام: كل قسم بيبدأ بسطر عنوان (وأول قسم = اللي قبل أول عنوان)
sections, cur = [], []
for ln in lines:
    if header.match(ln) and cur:
        sections.append(''.join(cur))
        cur = []
    cur.append(ln)
sections.append(''.join(cur))

# تجميع الأقسام في أجزاء تحت الحد (قسم أكبر من الحد بيبقى جزء لوحده)
parts, buf = [], ''
for s in sections:
    if buf and len((buf + s).encode('utf-8')) > LIMIT:
        parts.append(buf)
        buf = ''
    buf += s
parts.append(buf)

OUT.mkdir(exist_ok=True)
for old in OUT.glob('*.sql'):
    old.unlink()
total = len(parts)
for i, p in enumerate(parts, 1):
    note = f'-- الجزء {i} من {total} — شغّل الأجزاء بالترتيب (اتعمل من migrate_all.sql بـ tool/split_sql.py)\n'
    (OUT / f'{i:02d}_migrate.sql').write_text(note + p, encoding='utf-8', newline='')
    print(f'{i:02d}_migrate.sql  {len(p.encode("utf-8")) // 1024} KB')
assert ''.join(parts) == ''.join(lines), 'التقسيم غيّر المحتوى'
print(f'{total} parts - identical to migrate_all.sql when joined')
