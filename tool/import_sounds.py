"""بيجهّز نغمات الأبلكيشن من الملفات اللي اختارها صاحب المشروع ويحطها في مكانها.

لكل ملف WAV: بيشيل السكوت من الأول والآخر، يقصّ الطويل (أقصى ٢.٢ ثانية) بخفوت ناعم في الآخر، ويحوّله 16-bit.
ملفات mp3 / m4a بتتنسخ زي ما هي (مفيش أداة هنا تقصّها).

التشغيل من جذر المشروع:   python tool/import_sounds.py "C:/Users/AMR/Downloads"
بيكتب في assets/sounds (جوه الأبلكيشن) و android/app/src/main/res/raw (إشعارات أندرويد والأبلكيشن مقفول).
"""
import os
import shutil
import sys
import wave

import numpy as np

SRC = sys.argv[1] if len(sys.argv) > 1 else '.'
ASSETS = 'assets/sounds'
RAW = 'android/app/src/main/res/raw'
MAX_SECONDS = 2.2

# (جزء من اسم الملف الأصلي، الاسم الجديد، يتحط في res/raw لإشعارات أندرويد؟)
FILES = [
    ('كل جون', 'goal', True),                       # كل هدف
    ('نهايه و بدايه الماتش', 'match', True),        # بداية ونهاية الماتش
    ('تشكيله الماتش تنزل', 'lineup', True),         # التشكيلة نزلت
    ('الجوله بدأت', 'round_start', True),           # الجولة بدأت
    ('ديدلاين', 'deadline', True),                  # قبل الديدلاين بساعتين
    ('نوتيفيكيشن عاديه', 'general', True),          # أي إشعار تاني
    ('بدايه الابليكيشن', 'app_start', False),       # لما الأبلكيشن يفتح (جوه الأبلكيشن بس)
    ('مع كل لاعب', 'totw_reveal', False),           # كل لاعب بيظهر في كشف تشكيلة الجولة
]


def read_wav(path):
    with wave.open(path, 'rb') as w:
        ch, width, rate, n = w.getnchannels(), w.getsampwidth(), w.getframerate(), w.getnframes()
        raw = w.readframes(n)
    if width == 2:
        data = np.frombuffer(raw, '<i2').astype(np.float32) / 32768
    elif width == 3:                                 # 24-bit → float
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3).astype(np.int32)
        v = b[:, 0] | (b[:, 1] << 8) | (b[:, 2] << 16)
        v = np.where(v & 0x800000, v - 0x1000000, v)
        data = v.astype(np.float32) / 8388608
    elif width == 1:
        data = (np.frombuffer(raw, np.uint8).astype(np.float32) - 128) / 128
    else:
        raise ValueError(f'unsupported sample width {width}')
    return data.reshape(-1, ch), rate


def write_wav(path, data, rate):
    pcm = (np.clip(data, -1, 1) * 32767).round().astype('<i2')
    with wave.open(path, 'wb') as w:
        w.setnchannels(data.shape[1])
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())


def tidy(data, rate):
    """شيل السكوت من الطرفين، قصّ الطويل، وخفوت ناعم في الآخر."""
    level = np.abs(data).max(axis=1)
    loud = np.nonzero(level > 0.012)[0]
    if len(loud):
        data = data[max(loud[0] - int(0.01 * rate), 0): loud[-1] + int(0.05 * rate)]
    limit = int(MAX_SECONDS * rate)
    cut = len(data) > limit
    if cut:
        data = data[:limit].copy()
        fade = int(0.35 * rate)
        data[-fade:] *= np.linspace(1, 0, fade)[:, None] ** 2
    return data, cut


for folder in (ASSETS, RAW):
    os.makedirs(folder, exist_ok=True)
# النغمات القديمة المتولّدة بالكود
for old in ('goal.wav', 'whistle.wav', 'lineup.wav', 'soft.wav', 'win.wav'):
    for folder in (ASSETS, RAW):
        if os.path.exists(os.path.join(folder, old)):
            os.remove(os.path.join(folder, old))

names = os.listdir(SRC)
for part, new, to_raw in FILES:
    match = [n for n in names if part in n and n.lower().endswith(('.wav', '.mp3', '.m4a', '.ogg'))]
    if not match:
        print('MISSING', new)
        continue
    src = os.path.join(SRC, match[0])
    ext = os.path.splitext(src)[1].lower()
    out = new + ext
    if ext == '.wav':
        data, rate = read_wav(src)
        before = len(data) / rate
        data, cut = tidy(data, rate)
        write_wav(os.path.join(ASSETS, out), data, rate)
        note = f'{before:.1f}s -> {len(data) / rate:.1f}s' + (' (cut)' if cut else '')
    else:
        shutil.copyfile(src, os.path.join(ASSETS, out))
        note = 'copied as is'
    if to_raw:
        shutil.copyfile(os.path.join(ASSETS, out), os.path.join(RAW, out))
    print(f'{out:18} {note}')
