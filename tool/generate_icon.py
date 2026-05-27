"""GaleriPro masaüstü uygulama ikonu üretici.

Uygulamanın iç markasıyla uyumlu bir logo çizer:
  - Mavi gradyan (squircle) arka plan  (#1E3A8A -> #3B82F6)
  - Beyaz, yandan görünüm minimal araç silüeti + camlar + tekerlekler

Çıktılar:
  - windows/runner/resources/app_icon.ico   (16..256 px, çok boyutlu)
  - tool/icon_preview.png                    (256 px önizleme)

Çalıştırma:
  python tool/generate_icon.py
"""
import os
from PIL import Image, ImageDraw

# Süper-örnekleme (supersampling) çözünürlüğü — kenar yumuşatma için yüksek
S = 2048
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def p(f: float) -> int:
    """0..1 oranını master piksel koordinatına çevirir."""
    return int(round(f * S))


def build_gradient(c1, c2) -> Image.Image:
    """Köşegen (sol-üst -> sağ-alt) gradyan üretir."""
    small = Image.new("RGB", (64, 64))
    px = small.load()
    for y in range(64):
        for x in range(64):
            t = (x + y) / 126.0
            px[x, y] = (
                int(c1[0] + (c2[0] - c1[0]) * t),
                int(c1[1] + (c2[1] - c1[1]) * t),
                int(c1[2] + (c2[2] - c1[2]) * t),
            )
    return small.resize((S, S), Image.BILINEAR)


def main():
    WHITE = (255, 255, 255, 255)
    GLASS = (150, 190, 245, 255)   # camlar — açık mavi
    TIRE = (15, 27, 60, 255)       # lastik — koyu lacivert
    HUB = (236, 242, 255, 255)     # jant göbeği — açık

    # ── Gradyan arka plan + squircle maske ──────────────────────────────
    grad = build_gradient((30, 58, 138), (59, 130, 246))

    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [p(0.02), p(0.02), p(0.98), p(0.98)], radius=p(0.235), fill=255
    )

    icon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    icon.paste(grad, (0, 0), mask)

    d = ImageDraw.Draw(icon)

    # Tüm araç -0.02 yukarı kaydırılır (optik ortalama)
    dy = -0.02

    def pt(pairs):
        return [(p(x), p(y + dy)) for x, y in pairs]

    # ── Araç gövdesi (beyaz silüet) ─────────────────────────────────────
    body = [
        (0.165, 0.620), (0.165, 0.560), (0.235, 0.520), (0.330, 0.450),
        (0.420, 0.415), (0.585, 0.415), (0.680, 0.460), (0.775, 0.535),
        (0.835, 0.560), (0.835, 0.620),
    ]
    d.polygon(pt(body), fill=WHITE)
    # Gövde tabanını yuvarlat
    d.rounded_rectangle(
        [p(0.165), p(0.558 + dy), p(0.835), p(0.642 + dy)],
        radius=p(0.045), fill=WHITE,
    )

    # ── Camlar (açık mavi, kesilmiş görünüm) ────────────────────────────
    front_win = [(0.360, 0.512), (0.420, 0.440), (0.492, 0.440), (0.492, 0.512)]
    rear_win = [(0.508, 0.512), (0.508, 0.440), (0.578, 0.440),
                (0.652, 0.500), (0.652, 0.512)]
    d.polygon(pt(front_win), fill=GLASS)
    d.polygon(pt(rear_win), fill=GLASS)

    # ── Tekerlekler ─────────────────────────────────────────────────────
    for cx in (0.315, 0.685):
        cy, r, rh = 0.628, 0.090, 0.038
        d.ellipse([p(cx - r), p(cy - r + dy), p(cx + r), p(cy + r + dy)], fill=TIRE)
        d.ellipse([p(cx - rh), p(cy - rh + dy), p(cx + rh), p(cy + rh + dy)], fill=HUB)

    # ── Boyutlandır ve kaydet ───────────────────────────────────────────
    preview = icon.resize((256, 256), Image.LANCZOS)
    preview.save(os.path.join(HERE, "icon_preview.png"))

    sizes = [16, 24, 32, 48, 64, 128, 256]
    frames = [icon.resize((s, s), Image.LANCZOS) for s in sizes]
    out = os.path.join(ROOT, "windows", "runner", "resources", "app_icon.ico")
    frames[-1].save(out, format="ICO", sizes=[(s, s) for s in sizes],
                    append_images=frames[:-1])
    print("Yazildi:", out)
    print("Onizleme:", os.path.join(HERE, "icon_preview.png"))


if __name__ == "__main__":
    main()
