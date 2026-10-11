"""بيولّد أيقونة الأبلكيشن (PNG) من لوجو «الخاء والكورة» — أندرويد و iOS.

اللوجو متعرّف هندسيًا (viewBox 100×100) زي ملف التصميم:
  الحرف:  M24 44 H72 L32 66 Q20 73 25 83 Q30 91 48 91 H80   (سُمك 12 · أطراف مربعة)
  الكورة: دايرة (48,22) نصف قطرها 11 · وجواها رقعة خماسية

التشغيل من جذر المشروع:   python tool/make_icons.py
"""
import os
import struct
import zlib

import numpy as np

GREEN = (0x12, 0xA1, 0x50)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
STROKE = 12.0
PATCH = [(48, 17), (52.8, 20.5), (51, 26), (45, 26), (43.2, 20.5)]


def quad(p0, p1, p2, n=28):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in np.linspace(0, 1, n + 1)[1:]]


def letter_points():
    h = STROKE / 2
    pts = [(24 - h, 44), (72, 44), (32, 66)]            # أول طرف مربع: ممدود نص السُمك
    pts += quad((32, 66), (20, 73), (25, 83))
    pts += quad((25, 83), (30, 91), (48, 91))
    pts += [(80 + h, 91)]                               # آخر طرف مربع
    return pts


def in_polygon(x, y, poly):
    inside = np.zeros(x.shape, bool)
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, yi = poly[i]
        xj, yj = poly[j]
        cross = ((yi > y) != (yj > y)) & (x < (xj - xi) * (y - yi) / (yj - yi + 1e-12) + xi)
        inside ^= cross
        j = i
    return inside


def letter_mask(x, y):
    """جوه سُمك الحرف؟ مستطيل لكل قطعة + وصلات دايرة في المنحنيات + وصلة مشطوفة (bevel) في الزاوية الحادة."""
    h = STROKE / 2
    pts = letter_points()
    m = np.zeros(x.shape, bool)
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        dx, dy = bx - ax, by - ay
        ln = (dx * dx + dy * dy) ** 0.5
        ux, uy = dx / ln, dy / ln
        t = (x - ax) * ux + (y - ay) * uy
        d = np.abs((x - ax) * uy - (y - ay) * ux)
        m |= (t >= 0) & (t <= ln) & (d <= h)
    for (px, py) in pts[3:-1]:                          # وصلات المنحنيات
        m |= (x - px) ** 2 + (y - py) ** 2 <= h * h
    # الزاوية عند (72,44): bevel — مثلث بين الطرفين الخارجيين للقطعتين
    c = (72.0, 44.0)
    n1 = (0.0, -1.0)                                    # عمودي القطعة الأفقية (لبره = فوق)
    d2 = np.array([32 - 72, 66 - 44], float)
    d2 /= np.linalg.norm(d2)
    n2 = (d2[1], -d2[0])
    for s in (1, -1):
        tri = [c, (c[0] + s * n1[0] * h, c[1] + s * n1[1] * h), (c[0] + s * n2[0] * h, c[1] + s * n2[1] * h)]
        m |= in_polygon(x, y, tri)
    return m


def render(size, bg, letter, ball, patch, scale=0.72, plain_ball=False):
    """صورة RGB بمقاس size — اللوجو في النص بنسبة scale من المساحة."""
    ss = 4 if size <= 256 else 3
    n = size * ss
    coords = (np.arange(n) + 0.5) / n * 100.0
    gx, gy = np.meshgrid(coords, coords)
    off = (100 - 100 * scale) / 2
    x, y = (gx - off) / scale, (gy - off) / scale        # إحداثيات اللوجو
    img = np.empty((n, n, 3), np.float32)
    img[:] = bg
    img[letter_mask(x, y)] = letter
    img[(x - 48) ** 2 + (y - 22) ** 2 <= 121] = ball
    if not plain_ball:
        img[in_polygon(x, y, PATCH)] = patch
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
    return render(size, GREEN, WHITE, BLACK, GREEN, plain_ball=size < 40)


# أندرويد: الأيقونة القديمة (المربعة) لكل كثافة — الأجهزة الحديثة بتستخدم الـ adaptive (vector)
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
