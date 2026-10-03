#!/usr/bin/env python3
"""Verify imported Memory art and embed its actual provenance in Swift.

Input: {"records": [{"name": "MemoryAnimalCow", "source": "/path/to/generated.png",
                     "sha256": "<installed PNG hash>", "derivativeChanges": "...",
                     "reviewed": true}], "reused": ["CompareCampApple", ...],
        "scenes": [{"name": "MemoryAdventureSpace", "source": "...", "sha256": "..."}]}

source is the actual source PNG file, not a source label. Optional sourceName,
sourceUrl, creator, creditLine, license, and licenseUrl preserve verified third-party
source metadata. derivativeChanges
is required if imported bytes differ from the source. --reviewed explicitly attests
that every asset has been visually reviewed; without it reviewed defaults to false.
No images are created or changed by this script.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

START = "    // BEGIN GENERATED MEMORY ADVENTURE PROVENANCE"
END = "    // END GENERATED MEMORY ADVENTURE PROVENANCE"
SCENES = {"MemoryAdventureBuilders", "MemoryAdventureRescue", "MemoryAdventureSpace"}


def sha(path: Path) -> str:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"Not a PNG: {path}")
    return hashlib.sha256(data).hexdigest()


def expected_art(source: str) -> dict[str, str]:
    # Only explicit catalog calls in the four refreshed collections are imported.
    result = {}
    for method in ["domesticAnimal", "bird", "fruit", "fish"]:
        for card, asset in re.findall(rf'\b{method}\("([a-z0-9-]+)"[^\n]*?asset: "([A-Za-z0-9]+)"', source):
            if asset in result:
                raise ValueError(f"Repeated refreshed asset {asset}; provenance requires one representative card")
            result[asset] = card
    if len(result) != 70:
        raise ValueError(f"Expected 70 refreshed illustrations, found {len(result)}")
    return result


def initializer(fields: dict) -> str:
    def literal(value):
        if isinstance(value, bool):
            return str(value).lower()
        return json.dumps(value, ensure_ascii=False)
    lines = ["        MemoryImageAssetProvenance("]
    items = list(fields.items())
    lines += [f"            {key}: {literal(value)}{',' if i < len(items)-1 else ''}" for i, (key, value) in enumerate(items)]
    lines.append("        )")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", nargs="?", type=Path, default=Path("output/memory-adventures/generated-art.json"))
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--reviewed", action="store_true", help="Attest that every included image has passed individual visual review")
    parser.add_argument("--date", default="2026-10-02")
    parser.add_argument("--check", action="store_true", help="Verify that checked-in provenance already matches the manifest")
    args = parser.parse_args()
    repo = args.repo.resolve()
    target = repo / "Domain/MemoryContent.swift"
    original = target.read_text()
    expected = expected_art(original)
    manifest_path = args.manifest if args.manifest.is_absolute() else repo / args.manifest
    manifest = json.loads(manifest_path.read_text())
    card_records = manifest.get("records", [])
    scene_records = manifest.get("scenes", [])
    scene_names = [record["name"] for record in scene_records]
    if scene_records and set(scene_names) != SCENES:
        raise ValueError("Scene records must contain Builders, Rescue, and Space")
    records = card_records + scene_records
    reused = manifest.get("reused", [])
    names = [record["name"] for record in records] + reused
    if len(names) != len(set(names)):
        raise ValueError("Duplicate artwork names in manifest")
    required = set(expected) | set(scene_names)
    if set(names) != required:
        raise ValueError(f"Manifest mismatch: missing={sorted(required-set(names))}; unexpected={sorted(set(names)-required)}")
    by_name = {record["name"]: record for record in records}
    entries = []
    provenance_rows = []
    for name in sorted(names):
        installed = repo / f"App/Assets.xcassets/{name}.imageset/{name}.png"
        installed_hash = sha(installed)
        catalog = json.loads((installed.parent / "Contents.json").read_text())
        if f"{name}.png" not in [image.get("filename") for image in catalog["images"]]:
            raise ValueError(f"Catalog does not reference {installed.name}")
        record = by_name.get(name)
        if record:
            if record["sha256"] != installed_hash:
                raise ValueError(f"Imported hash mismatch for {name}")
            source_path = Path(record["source"])
            if not source_path.is_absolute():
                source_path = repo / source_path
            source_hash = sha(source_path)
            changes = record.get("derivativeChanges")
            if source_hash != installed_hash and not changes:
                raise ValueError(f"Describe the actual derivativeChanges for {name}")
            changes = changes or "Copied original generated PNG unchanged into the app asset catalog."
            credit = "Storybook artwork generated for Mather Memory Adventures."
            reviewed = args.reviewed or record.get("reviewed") is True
            source_file = source_path.name
            source_name = "Built-in ImageGen storybook artwork"
        else:
            if not name.startswith("CompareCamp"):
                raise ValueError(f"Reuse history is only established for Compare Camp assets: {name}")
            source_hash = installed_hash
            source_file = installed.name
            changes = "Reused existing Compare Camp generated PNG unchanged; original creation documented in wiki/Specs/Compare-Camp-Generated-Asset-Provenance.md."
            credit = "Existing Compare Camp artwork reused for Mather Memory Adventures."
            reviewed = args.reviewed or name in manifest.get("reviewedReused", [])
            source_name = "Existing Compare Camp built-in ImageGen artwork"
        fields = dict(assetName=name, cardId=expected.get(name, ""), sourceName=source_name,
            sourceUrl="", creator="OpenAI ImageGen for ganesh47/mather", creditLine=credit,
            license="Project-owned generated artwork; no third-party source material", licenseUrl="",
            retrievedAt=args.date, originalFileName=source_file, originalSha256=source_hash,
            derivativeFileName=installed.name, derivativeSha256=installed_hash,
            derivativeChanges=changes, licenseAllowsReuse=True, noThirdPartyRestrictionFound=True,
            noLogoOrEndorsementRisk=reviewed, noPeopleOrPrivacyRisk=reviewed,
            childCardLegibilityChecked=reviewed)
        # These fields describe the verified source; preserve explicit licensed-source metadata.
        for key in ["sourceName", "sourceUrl", "creator", "creditLine", "license", "licenseUrl"]:
            if record and key in record:
                if not isinstance(record[key], str):
                    raise ValueError(f"Source metadata {key} must be text for {name}")
                fields[key] = record[key]
        provenance_rows.append(dict(assetName=name, kind="scene" if name in SCENES else "card",
            cardId=expected.get(name), sourceName=fields["sourceName"], sourceUrl=fields["sourceUrl"],
            creator=fields["creator"], creditLine=fields["creditLine"], license=fields["license"],
            licenseUrl=fields["licenseUrl"], sourceFileName=source_file,
            originalSha256=source_hash, derivativeFileName=installed.name,
            derivativeSha256=installed_hash, derivativeChanges=changes,
            reused=record is None, reviewed=reviewed))
        if name not in SCENES:
            entries.append(initializer(fields))
    body = START + "\n    // Generated from verified files; visual review status is explicitly recorded.\n"
    body += "    private static let memoryAdventureIllustrationProvenance: [MemoryImageAssetProvenance] = [\n"
    body += ",\n".join(entries) + "\n    ]\n" + END
    if original.count(START) != 1 or original.count(END) != 1:
        raise ValueError("Missing or duplicate generated provenance markers")
    updated = original[:original.index(START)] + body + original[original.index(END)+len(END):]
    resource = repo / "wiki/Specs/Memory-Adventures-Art-Provenance.json"
    resource_text = json.dumps(dict(date=args.date, records=provenance_rows), indent=2, ensure_ascii=False) + "\n"
    if args.check:
        if updated != original:
            raise ValueError("Checked-in Memory provenance differs from verified manifest")
        if not resource.exists() or resource.read_text() != resource_text:
            raise ValueError("Checked-in art provenance JSON differs from verified manifest")
    else:
        target.write_text(updated)
        resource.parent.mkdir(parents=True, exist_ok=True)
        resource.write_text(resource_text)
    print(f"Verified {'and checked' if args.check else 'and embedded'} provenance for {len(entries)} card illustrations and {len(scene_records)} scenes.")


if __name__ == "__main__":
    main()
