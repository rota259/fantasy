"""بيولّد أيقونة الأبلكيشن (PNG) من لوجو «الصديري ورقم 5» — أندرويد و iOS.

اللوجو متعرّف هندسيًا (viewBox 100×100) زي ملف التصميم:
  الصديري: M33 9 H43 C45 21 55 21 57 9 H67 C67 22 73 28 81 30 V91 H19 V30 C27 28 33 22 33 9 Z
  الـ5 (جوه translate(17 26.8) scale(.66)): M72 14 H30 V50.7 A24 24 0 1 1 33 81  (سُمك 13 · أطراف مربعة)
  نقطة السنتر: دايرة (50,64) نصف قطرها 7

الأيقونة = نفس شكل الهوية: صديري أخضر و5 بيضا ونقطة حبر على خلفية فاتحة.
التشغيل من جذر المشروع:   python tool/make_icons.py
"""
import math
import os
import struct
import zlib

import numpy as np

PAPER = (0xF3, 0xF2, 0xF2)
TURF = (0x12, 0xA1, 0x50)
WHITE = (255, 255, 255)
INK = (0x20, 0x1E, 0x1D)
STROKE = 13.0


def cubic(p0, p1, p2, p3, n=24):
    out = []
    for t in np.linspace(0, 1, n + 1)[1:]:
        a, b, c, d = (1 - t) ** 3, 3 * (1 - t) ** 2 * t, 3 * (1 - t) * t * t, t ** 3
        out.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return out


def bib_polygon():
    pts = [(33, 9), (43, 9)]
    pts += cubic((43, 9), (45, 21), (55, 21), (57, 9))
    pts += [(67, 9)]
    pts += cubic((67, 9), (67, 22), (73, 28), (81, 30))
    pts += [(81, 91), (19, 91), (19, 30)]
    pts += cubic((19, 30), (27, 28), (33, 22), (33, 9))
    return pts


def arc_params(p1, p2, r):
    """قوس SVG (large-arc=1, sweep=1): المركز، زاوية البداية، ومقدار اللفّة (مع عقارب الساعة على الشاشة)."""
    (x1, y1), (x2, y2) = p1, p2
    mx, my = (x1 + x2) / 2, (y1 + y2) / 2
    dx, dy = x2 - x1, y2 - y1
    q = math.hypot(dx, dy)
    hgt = math.sqrt(max(r * r - (q / 2) ** 2, 0))
    for sign in (1, -1):
        cx, cy = mx + sign * hgt * (-dy / q), my + sign * hgt * (dx / q)
        a1, a2 = math.atan2(y1 - cy, x1 - cx), math.atan2(y2 - cy, x2 - cx)
        sweep = (a2 - a1) % (2 * math.pi)                # y لتحت → الزاوية بتزيد مع عقارب الساعة
        if sweep > math.pi:                              # القوس الكبير
            return cx, cy, a1, sweep
    raise ValueError('no arc')


def in_polygon(x, y, poly):
    inside = np.zeros(x.shape, bool)
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        inside ^= ((yi > y) != (yj > y)) & (x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi)
        j = i
    return inside


def five_mask(x, y):
    """جوه سُمك الـ5؟ (إحداثيات مجموعة الـ5) — القوس محسوب هندسيًا (حلقة + زاوية) عشان يطلع ناعم."""
    h = STROKE / 2
    r = 24.0
    cx, cy, a1, sweep = arc_params((30, 50.7), (33, 81), r)

    def rect(sx, sy, ex, ey):
        dx, dy = ex - sx, ey - sy
        L = math.hypot(dx, dy)
        ux, uy = dx / L, dy / L
        t = (x - sx) * ux + (y - sy) * uy
        d = np.abs((x - sx) * uy - (y - sy) * ux)
        return (t >= 0) & (t <= L) & (d <= h)

    # الخط الأفقي (طرف مربع يمين + زاوية قايمة شمال) والعمود
    m = rect(72 + h, 14, 30 - h, 14) | rect(30, 14 - h, 30, 50.7)
    # القوس: حلقة بسُمك الخط، في حدود زاويته
    dist = np.hypot(x - cx, y - cy)
    ang = (np.arctan2(y - cy, x - cx) - a1) % (2 * math.pi)
    m |= (np.abs(dist - r) <= h) & (ang <= sweep)
    # الطرف المربع في آخر القوس: امتداد نص السُمك على المماس
    a2 = a1 + sweep
    ex, ey = cx + r * math.cos(a2), cy + r * math.sin(a2)
    tx, ty = -math.sin(a2), math.cos(a2)
    m |= rect(ex, ey, ex + tx * h, ey + ty * h)
    # عند (30,50.7) الخط بيرجع بزاوية حادة → وصلة مشطوفة (bevel) زي الـ SVG
    c = (30.0, 50.7)
    t0 = (-math.sin(a1), math.cos(a1))
    n2 = (t0[1], -t0[0])
    for s1 in (1, -1):
        for s2 in (1, -1):
            m |= in_polygon(x, y, [c, (c[0] + s1 * h, c[1]), (c[0] + s2 * n2[0] * h, c[1] + s2 * n2[1] * h)])
    return m


def render(size, bg, bib, five, spot, scale=0.74, plain=False):
    ss = 4 if size <= 256 else 3
    n = size * ss
    coords = (np.arange(n) + 0.5) / n * 100.0
    gx, gy = np.meshgrid(coords, coords)
    off = (100 - 100 * scale) / 2
    x, y = (gx - off) / scale, (gy - off) / scale        # إحداثيات اللوجو
    fx, fy = (x - 17) / 0.66, (y - 26.8) / 0.66          # إحداثيات مجموعة الـ5
    img = np.empty((n, n, 3), np.float32)
    img[:] = bg
    img[in_polygon(x, y, bib_polygon())] = bib
    img[five_mask(fx, fy)] = five
    if not plain:
        img[(fx - 50) ** 2 + (fy - 64) ** 2 <= 49] = spot
    return img.reshape(size, ss, size, ss, 3).mean(axis=(1, 3)).round().astype(np.uint8)


def save_png(path, rgb):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    h, w, _ = rgb.shape
    raw = b''.join(b'\x00' + rgb[r].tobytes() for r in range(h))

    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)

    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
                + chunk(b'IDAT', zlib.compress(raw, 9)) + chunk(b'IEND', b''))


def icon(size):
    return render(size, PAPER, TURF, WHITE, INK, plain=size < 40)


# أندرويد: الأيقونة المربعة لكل كثافة (الأجهزة الحديثة بتستخدم الـ adaptive — vector)
for name, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    save_png(f'android/app/src/main/res/mipmap-{name}/ic_launcher.png', icon(size))

# iOS
IOS = {'20x20@1x': 20, '20x20@2x': 40, '20x20@3x': 60, '29x29@1x': 29, '29x29@2x': 58, '29x29@3x': 87,
       '40x40@1x': 40, '40x40@2x': 80, '40x40@3x': 120, '60x60@2x': 120, '60x60@3x': 180, '76x76@1x': 76,
       '76x76@2x': 152, '83.5x83.5@2x': 167, '1024x1024@1x': 1024}
for name, size in IOS.items():
    save_png(f'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-{name}.png', icon(size))

# نسخة كبيرة للمتجر
save_png('assets/brand/app_icon_1024.png', icon(1024))
print('icons written')
