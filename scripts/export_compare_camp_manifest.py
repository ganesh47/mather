#!/usr/bin/env python3
"""Export the curated camp inventory and asset provenance for review."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FIELDS = ["id", "title", "subtitle", "region", "singular", "plural", "symbol", "asset", "accentHex"]
PATTERN = r'camp\("([^\"]+)", "([^\"]+)", "([^\"]+)", \.(\w+), "([^\"]+)", "([^\"]+)", "([^\"]+)", "([^\"]+)", "([^\"]+)"\)'


def main():
    rows = re.findall(PATTERN, (ROOT / "Domain/CompareCampContent.swift").read_text())
    if len(rows) != 24:
        raise ValueError("Expected the 24 curated camps; update the exporter when the catalog format changes.")
    categories = [dict(zip(FIELDS, row)) for row in rows]
    for category in categories:
        asset = ROOT / "App/Assets.xcassets" / (category["asset"] + ".imageset")
        if not asset.is_dir():
            raise ValueError("Missing camp artwork: " + category["asset"])
    generated = []
    for image in sorted((ROOT / "App/Assets.xcassets").glob("CompareCamp*.imageset/*.png")):
        generated.append({"name": image.stem, "path": str(image.relative_to(ROOT)),
                          "sha256": hashlib.sha256(image.read_bytes()).hexdigest()})
    manifest = {"schemaVersion": 1, "categoryCount": len(categories), "categories": categories,
                "activities": ["adventure", "more", "fewer", "makeEqual", "difference", "symbols"],
                "difficultyMaxima": {"small": 5, "growing": 10, "big": 20},
                "stopsPerTrail": 8, "generatedAssets": generated}
    output = ROOT / "output/compare-camp/content-manifest.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2) + "\n")
    print(output)


if __name__ == "__main__":
    main()
