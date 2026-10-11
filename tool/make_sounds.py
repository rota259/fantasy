"""بيولّد أصوات الإشعارات (WAV قصيرة) — متولّدة بالكود، فمفيش حقوق ملكية لحد.

التشغيل من جذر المشروع:   python tool/make_sounds.py
بيكتب في assets/sounds (جوه الأبلكيشن) و android/app/src/main/res/raw (إشعارات أندرويد والأبلكيشن مقفول).
"""
import math
import os
import struct
import wave

RATE = 22050


def env(t, dur, attack=0.01, release=0.15):
    """ظهور سريع واختفاء ناعم (من غير طقطقة)."""
    if t < attack:
        return t / attack
    if t > dur - release:
        return max(0.0, (dur - t) / release)
    return 1.0


def tone(freq, dur, vol=0.5, decay=4.0, harmonics=(1.0, 0.35, 0.12)):
    """نغمة جرس: أساسي + توافقيات، بتخفت مع الوقت."""
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        s = sum(a * math.sin(2 * math.pi * freq * (k + 1) * t) for k, a in enumerate(harmonics))
        out.append(vol * s * math.exp(-decay * t) * env(t, dur))
    return out


def silence(dur):
    return [0.0] * int(RATE * dur)


def mix(*tracks):
    n = max(len(t) for t in tracks)
    return [sum(t[i] if i < len(t) else 0.0 for t in tracks) for i in range(n)]


def at(offset, track):
    return silence(offset) + track


def whistle(dur, vol=0.45):
    """صفارة حكم: نغمة عالية بترعش (البلية جوه الصفارة)."""
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        trill = 0.75 + 0.25 * math.sin(2 * math.pi * 38 * t)
        f = 2850 + 60 * math.sin(2 * math.pi * 6 * t)
        s = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * 2 * f * t)
        out.append(vol * trill * s * env(t, dur, 0.015, 0.06))
    return out


def save(name, samples):
    peak = max(1e-9, max(abs(x) for x in samples))
    scale = min(1.0, 0.89 / peak)
    data = b''.join(struct.pack('<h', int(max(-1.0, min(1.0, x * scale)) * 32767)) for x in samples)
    for folder in ('assets/sounds', 'android/app/src/main/res/raw'):
        os.makedirs(folder, exist_ok=True)
        with wave.open(os.path.join(folder, name + '.wav'), 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(data)
    print(f'{name}.wav  {len(samples) / RATE:.2f}s')


C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0
A4, D5, A5 = 440.0, 587.33, 880.0

# جول: نغمتين طالعين بسرعة وبعدهم نغمة عالية بترن — فرحة قصيرة
save('goal', mix(tone(G5, 0.18, 0.5, 9), at(0.10, tone(C6, 0.18, 0.5, 9)), at(0.20, tone(E6, 0.7, 0.55, 4)),
                 at(0.20, tone(G6, 0.7, 0.25, 5))))

# ماتش (بدأ/خلص/ميعاد): صفارتين حكم
save('whistle', whistle(0.22) + silence(0.07) + whistle(0.45))

# التشكيلة نزلت: نقرتين ناعمين
save('lineup', mix(tone(A5, 0.16, 0.45, 14, (1.0, 0.2)), at(0.13, tone(D5 * 2, 0.3, 0.45, 9, (1.0, 0.2)))))

# حالة لاعب / حجز / عام: نغمة واحدة هادية
save('soft', mix(tone(E5, 0.5, 0.4, 6, (1.0, 0.15)), at(0.02, tone(A4, 0.5, 0.2, 6, (1.0,)))))

# كسبت (شارة / تحدّي / تصويت): سلّم طالع C-E-G-C
save('win', mix(tone(C5, 0.2, 0.42, 8), at(0.09, tone(E5, 0.2, 0.42, 8)), at(0.18, tone(G5, 0.2, 0.42, 8)),
                at(0.27, tone(C6, 0.75, 0.5, 4))))
