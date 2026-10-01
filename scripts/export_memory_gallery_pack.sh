#!/bin/bash
set -euo pipefail

# Export a starting pack, then edit pack.json independently of the app source.
# Usage: scripts/export_memory_gallery_pack.sh OUTPUT_DIRECTORY CONTENT_VERSION [SOURCE_PACK_JSON]
repo_root=$(cd "$(dirname "$0")/.." && pwd)
task_dir=$(mktemp -d)
trap 'rm -rf "$task_dir"' EXIT
cat > "$task_dir/main.swift" <<'SWIFT'
import CryptoKit
import Foundation
import ImageIO

guard CommandLine.arguments.count == 5,
      let version = Int(CommandLine.arguments[2]), version > 1 else {
    fatalError("Usage: export_memory_gallery_pack.sh OUTPUT_DIRECTORY CONTENT_VERSION (greater than 1)")
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let repo = URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
let input = URL(fileURLWithPath: CommandLine.arguments[4])
let sourcePack = try JSONDecoder().decode(MemoryGalleryContentPack.self, from: Data(contentsOf: input))
try sourcePack.validate()
let decks = sourcePack.decks
let names = Set(decks.flatMap(\.cards).compactMap(\.imageAssetName)
    + decks.flatMap(\.cards).flatMap(\.learningArtwork).map(\.assetName)).sorted()
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var assets: [MemoryGalleryContentPack.Asset] = []
for name in names {
    let external = input.deletingLastPathComponent().appendingPathComponent("\(name).png")
    let source = FileManager.default.fileExists(atPath: external.path) ? external
        : repo.appendingPathComponent("App/Assets.xcassets/\(name).imageset/\(name).png")
    let data = try Data(contentsOf: source)
    guard data.starts(with: [137, 80, 78, 71, 13, 10, 26, 10]),
          let image = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int,
          (1...4096).contains(width), (1...4096).contains(height),
          CGImageSourceCreateImageAtIndex(image, 0, nil) != nil else { fatalError("Invalid PNG: \(source.path)") }
    try data.write(to: output.appendingPathComponent("\(name).png"), options: .atomic)
    assets.append(.init(id: name, file: "\(name).png", byteCount: data.count,
                        sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()))
}
let pack = MemoryGalleryContentPack(schemaVersion: 1, contentVersion: version, decks: decks, assets: assets)
try pack.validate()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
try encoder.encode(pack).write(to: output.appendingPathComponent("pack.json"), options: .atomic)
let suppliedCreditsURL = input.deletingLastPathComponent().appendingPathComponent("attribution.json")
let suppliedCredits = FileManager.default.fileExists(atPath: suppliedCreditsURL.path)
    ? try JSONDecoder().decode([MemoryImageAssetProvenance].self, from: Data(contentsOf: suppliedCreditsURL)) : []
let suppliedNames = Set(suppliedCredits.map(\.assetName))
let credits = (suppliedCredits + MemoryDeck.imageAssetProvenance.filter { !suppliedNames.contains($0.assetName) })
    .filter { names.contains($0.assetName) }
guard Set(credits.map(\.assetName)) == Set(names) else { fatalError("Missing image provenance") }
try encoder.encode(credits).write(to: output.appendingPathComponent("attribution.json"), options: .atomic)
print("Exported version \(version): \(decks.reduce(0) { $0 + $1.cards.count }) cards and \(assets.count) images to \(output.path)")
SWIFT
swiftc "$repo_root/Domain/MemoryContent.swift" "$repo_root/Domain/MemoryGalleryTVRound.swift" \
    "$repo_root/Domain/MemoryGalleryContentPack.swift" "$task_dir/main.swift" -o "$task_dir/export"
"$task_dir/export" "${1:?Output directory required}" "${2:?Content version required}" "$repo_root" \
    "${3:-$repo_root/Content/MemoryGallery/pack.json}"
