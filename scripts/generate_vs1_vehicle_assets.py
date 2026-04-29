#!/usr/bin/env python3
"""Generate project-owned VS1 vehicle counter assets.

The drawings are deterministic, simple Pillow vector shapes: no third-party
source images, logos, screenshots, or web material are used.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "App" / "Assets.xcassets"
SIZE = 512

COLORS = {
    "outline": (64, 55, 49, 255), "window": (179, 224, 242, 255),
    "tire": (55, 55, 59, 255), "hub": (238, 238, 230, 255),
    "shadow": (88, 75, 64, 45), "red": (239, 104, 96, 255),
    "yellow": (247, 190, 74, 255), "orange": (238, 146, 65, 255),
    "green": (95, 184, 128, 255), "teal": (86, 184, 190, 255),
    "blue": (96, 153, 215, 255),
}

def rr(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)

def wheel(draw, x, y, r=34):
    draw.ellipse((x-r, y-r, x+r, y+r), fill=COLORS["tire"])
    draw.ellipse((x-r+13, y-r+13, x+r-13, y+r-13), fill=COLORS["hub"])

def base_image():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((78, 360, 434, 420), fill=COLORS["shadow"])
    return im, d

def save(name, draw_fn):
    im, d = base_image(); draw_fn(d)
    out_dir = ASSETS / f"{name}.imageset"; out_dir.mkdir(parents=True, exist_ok=True)
    im.save(out_dir / f"{name}.png")
    (out_dir / "Contents.json").write_text(
        '{\n  "images": [\n    {\n      "idiom": "universal",\n      "filename": "' + name + '.png",\n      "scale": "1x"\n    },\n    {\n      "idiom": "universal",\n      "scale": "2x"\n    },\n    {\n      "idiom": "universal",\n      "scale": "3x"\n    }\n  ],\n  "info": {\n    "version": 1,\n    "author": "xcode"\n  }\n}\n'
    )

def car(d):
    rr(d, (116, 236, 396, 334), 38, COLORS["red"], COLORS["outline"], 8)
    d.polygon([(178, 236), (224, 176), (314, 176), (360, 236)], fill=COLORS["red"], outline=COLORS["outline"])
    d.line([(178, 236), (224, 176), (314, 176), (360, 236)], fill=COLORS["outline"], width=8, joint="curve")
    rr(d, (226, 190, 270, 230), 10, COLORS["window"], COLORS["outline"], 5); rr(d, (280, 190, 324, 230), 10, COLORS["window"], COLORS["outline"], 5)
    wheel(d, 178, 336); wheel(d, 334, 336)

def pickup(d):
    rr(d, (118, 232, 408, 326), 26, COLORS["teal"], COLORS["outline"], 8)
    d.line((250, 234, 250, 318), fill=COLORS["outline"], width=8)
    rr(d, (270, 252, 378, 302), 8, (115, 204, 207, 255), COLORS["outline"], 5)
    d.polygon([(130, 232), (178, 178), (254, 178), (292, 232)], fill=COLORS["teal"], outline=COLORS["outline"])
    rr(d, (178, 190, 238, 228), 8, COLORS["window"], COLORS["outline"], 5)
    wheel(d, 178, 330); wheel(d, 344, 330)

def bulldozer(d):
    rr(d, (120, 242, 322, 328), 24, COLORS["yellow"], COLORS["outline"], 8)
    rr(d, (186, 172, 280, 250), 18, COLORS["yellow"], COLORS["outline"], 8)
    rr(d, (204, 190, 266, 238), 10, COLORS["window"], COLORS["outline"], 5)
    d.polygon([(324, 265), (412, 230), (420, 336), (326, 330)], fill=COLORS["orange"], outline=COLORS["outline"])
    d.line((322, 276, 412, 238), fill=COLORS["outline"], width=8)
    rr(d, (104, 320, 340, 374), 26, COLORS["tire"], COLORS["outline"], 4)
    for x in (152, 222, 292): wheel(d, x, 347, 24)

def dump_truck(d):
    d.polygon([(104, 206), (292, 206), (318, 310), (112, 310)], fill=COLORS["orange"], outline=COLORS["outline"])
    rr(d, (302, 234, 410, 326), 22, COLORS["teal"], COLORS["outline"], 8)
    rr(d, (330, 250, 386, 292), 10, COLORS["window"], COLORS["outline"], 5)
    d.line((116, 230, 300, 230), fill=(255, 205, 122, 255), width=12)
    wheel(d, 170, 330); wheel(d, 350, 330)

def cement_mixer(d):
    rr(d, (250, 242, 408, 326), 22, COLORS["green"], COLORS["outline"], 8)
    rr(d, (282, 256, 378, 296), 10, COLORS["window"], COLORS["outline"], 5)
    d.ellipse((104, 180, 300, 326), fill=COLORS["blue"], outline=COLORS["outline"], width=8)
    d.line((142, 210, 268, 294), fill=(230, 244, 252, 255), width=18)
    d.line((130, 270, 252, 196), fill=(230, 244, 252, 255), width=18)
    rr(d, (118, 306, 384, 338), 12, COLORS["outline"])
    wheel(d, 172, 340); wheel(d, 346, 340)

def mining_truck(d):
    d.polygon([(92, 186), (302, 206), (286, 308), (106, 308)], fill=COLORS["yellow"], outline=COLORS["outline"])
    rr(d, (296, 226, 420, 318), 20, COLORS["orange"], COLORS["outline"], 8)
    rr(d, (326, 242, 390, 286), 10, COLORS["window"], COLORS["outline"], 5)
    wheel(d, 172, 330, 48); wheel(d, 354, 330, 48)

VEHICLES = {
    "VS1VehicleCar": car,
    "VS1VehiclePickupTruck": pickup,
    "VS1VehicleBulldozer": bulldozer,
    "VS1VehicleDumpTruck": dump_truck,
    "VS1VehicleCementMixer": cement_mixer,
    "VS1VehicleMiningTruck": mining_truck,
}

if __name__ == "__main__":
    for asset, fn in VEHICLES.items(): save(asset, fn)
    print(f"Generated {len(VEHICLES)} VS1 vehicle assets in {ASSETS}")
