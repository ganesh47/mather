#!/bin/bash
set -euo pipefail

# Export a starting catalog, then edit catalog.json independently of app source.
# Usage: scripts/export_ios_learning_catalog.sh OUTPUT_DIRECTORY CONTENT_VERSION
repo_root=$(cd "$(dirname "$0")/.." && pwd)
task_dir=$(mktemp -d)
trap 'rm -rf "$task_dir"' EXIT
cat > "$task_dir/main.swift" <<'SWIFT'
import CryptoKit
import Foundation
import ImageIO

guard CommandLine.arguments.count == 5,
      let version = Int(CommandLine.arguments[2]), version > 1 else {
    fatalError("Usage: export_ios_learning_catalog.sh OUTPUT_DIRECTORY CONTENT_VERSION (greater than 1)")
}
let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let repo = URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
let input = URL(fileURLWithPath: CommandLine.arguments[4])
let sourcePack = IOSLearningCatalog.bundled
try sourcePack.validate()
let decks = sourcePack.decks
let threads = sourcePack.threads
let bundledCredits = Set(MemoryDeck.imageAssetProvenance.map(\.assetName))
let names = Set(decks.flatMap(\.cards).compactMap(\.imageAssetName)
    + decks.flatMap(\.cards).flatMap(\.learningArtwork).map(\.assetName)
    + threads.flatMap(\.entities).compactMap(\.visualAssetName)
    + threads.flatMap(\.entities).flatMap(\.properties).compactMap(\.visualAssetName)).sorted()
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var assets: [MemoryGalleryContentPack.Asset] = []
for name in names {
    // Code-shipped vector illustrations remain bundled. Publishers can later
    // override the same ID with a verified PNG without changing the app.
    let vector = repo.appendingPathComponent("App/Assets.xcassets/\(name).imageset/\(name).svg")
    if FileManager.default.fileExists(atPath: vector.path) || !bundledCredits.contains(name) { continue }
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
let pack = IOSLearningCatalog(schemaVersion: 1, contentVersion: version, decks: decks, threads: threads, assets: assets)
try pack.validate()
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
try encoder.encode(pack).write(to: output.appendingPathComponent("catalog.json"), options: .atomic)
let suppliedCreditsURL = input.deletingLastPathComponent().appendingPathComponent("attribution.json")
let suppliedCredits = FileManager.default.fileExists(atPath: suppliedCreditsURL.path)
    ? try JSONDecoder().decode([MemoryImageAssetProvenance].self, from: Data(contentsOf: suppliedCreditsURL)) : []
let suppliedNames = Set(suppliedCredits.map(\.assetName))
let exportedNames = Set(assets.map(\.id))
let credits = (suppliedCredits + MemoryDeck.imageAssetProvenance.filter { !suppliedNames.contains($0.assetName) })
    .filter { exportedNames.contains($0.assetName) }
guard Set(credits.map(\.assetName)) == exportedNames else { fatalError("Missing image provenance: \(exportedNames.subtracting(credits.map(\.assetName)).sorted())") }
try encoder.encode(credits).write(to: output.appendingPathComponent("attribution.json"), options: .atomic)
print("Exported version \(version): \(decks.reduce(0) { $0 + $1.cards.count }) cards and \(assets.count) images to \(output.path)")
SWIFT
source "$repo_root/scripts/ios_learning_sources.sh"
swiftc "${ios_learning_sources[@]}" "$task_dir/main.swift" -o "$task_dir/export"
"$task_dir/export" "${1:?Output directory required}" "${2:?Content version required}" "$repo_root" \
    "$repo_root/Content/MemoryGallery/pack.json"
