// Usage: rename_pdfs <source-dir> <dest-dir>
// Renames each PDF in source-dir to the first line of text on its first page,
// and moves it into dest-dir. Prints one line per file, then a summary.
import Foundation
import PDFKit

let args = CommandLine.arguments
guard args.count == 3 else {
    print("usage: rename_pdfs <source-dir> <dest-dir>")
    exit(2)
}
let fm = FileManager.default
let src = URL(fileURLWithPath: args[1], isDirectory: true)
let dst = URL(fileURLWithPath: args[2], isDirectory: true)

func cleanName(_ s: String) -> String {
    var name = s.replacingOccurrences(of: "[/:\\\\*?\"<>|]", with: "-", options: .regularExpression)
    name = name.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    name = name.trimmingCharacters(in: CharacterSet(charactersIn: ". ").union(.whitespacesAndNewlines))
    return String(name.prefix(150))
}

func headerName(of url: URL) -> String? {
    guard let text = PDFDocument(url: url)?.page(at: 0)?.string else { return nil }
    for line in text.split(whereSeparator: \.isNewline) {
        let n = cleanName(String(line))
        if !n.isEmpty { return n }
    }
    return nil
}

func uniqueURL(_ base: String) -> URL {
    var url = dst.appendingPathComponent(base + ".pdf")
    var i = 2
    while fm.fileExists(atPath: url.path) {
        url = dst.appendingPathComponent("\(base) (\(i)).pdf")
        i += 1
    }
    return url
}

let files = ((try? fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? [])
    .filter { $0.pathExtension.lowercased() == "pdf" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent }

var moved = 0, skipped = 0
for f in files {
    guard let name = headerName(of: f) else {
        print("SKIPPED (no readable text): \(f.lastPathComponent)")
        skipped += 1
        continue
    }
    let target = uniqueURL(name)
    do {
        try fm.moveItem(at: f, to: target)
        print("\(f.lastPathComponent)  ->  \(target.lastPathComponent)")
        moved += 1
    } catch {
        print("FAILED: \(f.lastPathComponent) (\(error.localizedDescription))")
        skipped += 1
    }
}
print("Done: \(moved) renamed and moved, \(skipped) skipped.")
