#!/usr/bin/env python3
"""Generate playful, non-spendable currency clue cards for Memory Gallery."""

from pathlib import Path
import json

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "App" / "Assets.xcassets"
FONT = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
ROUNDED_FONT = "/System/Library/Fonts/SFNSRounded.ttf"
INDIC_FONT = "/System/Library/Fonts/Kohinoor.ttc"

COUNTRIES = [
    ("India", "INR", "₹", "Indian rupee", "#FFB23F", "#138B67"),
    ("Japan", "JPY", "¥", "Japanese yen", "#F45B69", "#FFF8EE"),
    ("France", "EUR", "€", "Euro", "#3D68D8", "#ED5A67"),
    ("Egypt", "EGP", "E£", "Egyptian pound", "#D7A23A", "#2F7C65"),
    ("Brazil", "BRL", "R$", "Brazilian real", "#23A567", "#F4D44D"),
    ("Australia", "AUD", "A$", "Australian dollar", "#3D71D8", "#65C6C4"),
    ("Canada", "CAD", "C$", "Canadian dollar", "#E65454", "#FFF6E9"),
    ("Kenya", "KES", "KSh", "Kenyan shilling", "#D9534F", "#24855B"),
    ("UnitedStates", "USD", "$", "US dollar", "#4E78C4", "#63A36C"),
    ("UnitedKingdom", "GBP", "£", "Pound sterling", "#7450A8", "#E25B66"),
    ("China", "CNY", "¥", "Chinese yuan", "#E44E4E", "#F2C84B"),
    ("Germany", "EUR", "€", "Euro", "#E0A83F", "#3C3C42"),
    ("Mexico", "MXN", "Mex$", "Mexican peso", "#2B9968", "#D55A55"),
    ("SouthAfrica", "ZAR", "R", "South African rand", "#2D8B70", "#E2B845"),
    ("Italy", "EUR", "€", "Euro", "#2C9A67", "#E85D62"),
    ("SaudiArabia", "SAR", "SAR", "Saudi riyal", "#23845D", "#D6B857"),
]


def font(size: int, rounded: bool = True, path: str | None = None) -> ImageFont.FreeTypeFont:
    path = path or (ROUNDED_FONT if rounded else FONT)
    return ImageFont.truetype(path, size=size)


def centered(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, face, fill: str) -> None:
    box = draw.textbbox((0, 0), text, font=face)
    width = box[2] - box[0]
    height = box[3] - box[1]
    draw.text((xy[0] - width / 2, xy[1] - height / 2 - box[1]), text, font=face, fill=fill)


def generate(asset_name: str, code: str, symbol: str, currency: str, primary: str, accent: str) -> None:
    image = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    # Soft shadow and a deliberately toy-like note silhouette. It has no value,
    # serial number, seal, portrait, or security feature and cannot resemble cash.
    draw.rounded_rectangle((43, 91, 477, 421), radius=38, fill=(15, 28, 42, 42))
    draw.rounded_rectangle((27, 75, 461, 405), radius=38, fill=primary, outline="#FFFFFF", width=8)
    draw.rounded_rectangle((48, 96, 440, 384), radius=28, outline="#FFFFFFB8", width=5)

    for x in range(70, 430, 56):
        draw.ellipse((x - 12, 112, x + 12, 136), fill=accent)
        draw.ellipse((x - 8, 344, x + 8, 360), fill=accent)

    draw.ellipse((135, 135, 353, 353), fill="#FFF8E8", outline=accent, width=10)
    draw.arc((164, 166, 324, 326), 20, 160, fill=primary, width=7)
    draw.arc((164, 166, 324, 326), 200, 340, fill=primary, width=7)

    symbol_size = 94 if len(symbol) == 1 else (72 if len(symbol) == 2 else 58)
    symbol_font = font(symbol_size, rounded=False, path=INDIC_FONT if symbol == "₹" else None)
    centered(draw, (244, 239), symbol, symbol_font, primary)
    centered(draw, (244, 308), code, font(35), primary)
    centered(draw, (244, 449), currency, font(27), "#203040")
    centered(draw, (244, 373), "FOR LEARNING", font(17), "#FFFFFF")

    imageset = ASSETS / f"{asset_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    image.save(imageset / f"{asset_name}.png", optimize=True)
    contents = {
        "images": [
            {"filename": f"{asset_name}.png", "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


if __name__ == "__main__":
    for country, code, symbol, currency, primary, accent in COUNTRIES:
        generate(f"MemoryCurrency{country}", code, symbol, currency, primary, accent)
