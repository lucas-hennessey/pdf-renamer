// Usage: rename_pdfs <source-dir> <dest-dir>
// Renames each PDF in source-dir to its title (or, failing that, the largest text on page 1),
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

// Name = the PDF's built-in title if it has one, else the largest text in the top 40% of
// page 1 (wrapped title lines of that size are joined).
func headerName(of url: URL) -> String? {
    guard let doc = PDFDocument(url: url), let page = doc.page(at: 0) else { return nil }
    if let t = doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String {
        let name = cleanName(t)
        if name.contains(where: { $0.isLetter || $0.isNumber }) { return name }
    }
    let box = page.bounds(for: .cropBox)
    let top = box.minY + box.height * 0.6
    var lines: [(text: String, size: CGFloat, y: CGFloat, height: CGFloat)] = []
    for line in page.selection(for: box)?.selectionsByLine() ?? [] {
        let b = line.bounds(for: page)
        guard b.midY >= top, let attr = line.attributedString else { continue }
        var size: CGFloat = 0
        attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length)) { v, r, _ in
            let part = attr.attributedSubstring(from: r).string
            if let f = v as? NSFont, !part.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                size = max(size, f.pointSize)
            }
        }
        let text = cleanName(attr.string)
        if size > 0, text.contains(where: { $0.isLetter || $0.isNumber }) {
            lines.append((text, size, b.midY, b.height))
        }
    }
    guard let best = lines.max(by: { $0.size == $1.size ? $0.y < $1.y : $0.size < $1.size }) else { return nil }
    // Join directly adjacent lines of the same size below the first (wrapped titles).
    var parts = [best]
    for l in lines.filter({ abs($0.size - best.size) < 0.5 && $0.y < best.y }).sorted(by: { $0.y > $1.y }) {
        if parts.last!.y - l.y < best.height * 1.8 { parts.append(l) } else { break }
    }
    return cleanName(parts.map(\.text).joined(separator: " "))
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
