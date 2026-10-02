// Progress window for glass-import.sh.
// Polls the key=value status file the script writes and shows what is being
// copied, how far along it is, and where the files are going.
// Usage: GlassImportProgress [status-file]

import AppKit

let statusPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : NSHomeDirectory() + "/Library/Caches/GlassImporter/status"

func readStatus() -> [String: String] {
    guard let text = try? String(contentsOfFile: statusPath, encoding: .utf8) else { return [:] }
    var status: [String: String] = [:]
    for line in text.split(separator: "\n") {
        guard let eq = line.firstIndex(of: "=") else { continue }
        status[String(line[..<eq])] = String(line[line.index(after: eq)...])
    }
    return status
}

func fileSize(_ path: String) -> Int64 {
    ((try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? NSNumber)?.int64Value ?? 0
}

func bytes(_ n: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: n, countStyle: .file)
}

func tildePath(_ path: String) -> String {
    (path as NSString).abbreviatingWithTildeInPath
}

func duration(_ seconds: Double) -> String {
    let f = DateComponentsFormatter()
    f.unitsStyle = .full
    f.allowedUnits = seconds >= 3600 ? [.hour, .minute] : seconds >= 60 ? [.minute] : [.second]
    f.maximumUnitCount = 2
    return f.string(from: max(seconds, 1)) ?? ""
}

func label(_ font: NSFont, color: NSColor = .labelColor) -> NSTextField {
    let field = NSTextField(labelWithString: "")
    field.font = font
    field.textColor = color
    field.lineBreakMode = .byTruncatingMiddle
    field.maximumNumberOfLines = 1
    // Let long names truncate instead of stretching the window past its edge.
    field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    return field
}

final class ProgressController: NSObject, NSWindowDelegate {
    let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 460, height: 10),
                        styleMask: [.titled, .closable], backing: .buffered, defer: false)
    let icon = NSImageView()
    let headline = label(.systemFont(ofSize: 15, weight: .semibold))
    let detail = label(.systemFont(ofSize: 12))
    let bar = NSProgressIndicator()
    let amounts = label(.monospacedDigitSystemFont(ofSize: 11, weight: .regular), color: .secondaryLabelColor)
    let photosDest = label(.systemFont(ofSize: 11), color: .secondaryLabelColor)
    let videosDest = label(.systemFont(ofSize: 11), color: .secondaryLabelColor)
    let hint = label(.systemFont(ofSize: 11, weight: .medium), color: .systemOrange)
    lazy var finderButton = NSButton(title: "Show in Finder", target: self, action: #selector(showInFinder))
    lazy var closeButton = NSButton(title: "Hide", target: self, action: #selector(closeOrHide))

    var status: [String: String] = [:]
    var finished = false
    var hiddenByUser = false

    override init() {
        super.init()
        panel.title = "Google Glass Import"
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.delegate = self

        icon.image = NSImage(systemSymbolName: "eyeglasses", accessibilityDescription: nil)
        icon.symbolConfiguration = .init(pointSize: 28, weight: .regular)
        icon.contentTintColor = .controlAccentColor

        bar.style = .bar
        bar.minValue = 0
        bar.maxValue = 1
        bar.isIndeterminate = false

        closeButton.keyEquivalent = "\r"
        let buttons = NSStackView(views: [NSView(), finderButton, closeButton])
        buttons.orientation = .horizontal
        buttons.spacing = 8

        let text = NSStackView(views: [headline, detail, bar, amounts, photosDest, videosDest, hint])
        text.orientation = .vertical
        text.alignment = .leading
        text.spacing = 6
        text.setCustomSpacing(10, after: detail)
        text.setCustomSpacing(10, after: amounts)
        text.setCustomSpacing(2, after: photosDest)
        text.setCustomSpacing(10, after: videosDest)

        let top = NSStackView(views: [icon, text])
        top.orientation = .horizontal
        top.alignment = .top
        top.spacing = 14

        let root = NSStackView(views: [top, buttons])
        root.orientation = .vertical
        root.alignment = .trailing
        root.spacing = 16
        root.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 16, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false

        panel.contentView = root
        NSLayoutConstraint.activate([
            root.widthAnchor.constraint(equalToConstant: 460),
            top.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            top.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            buttons.widthAnchor.constraint(equalTo: top.widthAnchor),
            bar.widthAnchor.constraint(equalTo: text.widthAnchor),
            icon.widthAnchor.constraint(equalToConstant: 40),
            text.trailingAnchor.constraint(equalTo: top.trailingAnchor),
        ])
        for field in [headline, detail, amounts, photosDest, videosDest, hint] {
            field.widthAnchor.constraint(equalTo: text.widthAnchor).isActive = true
        }

        refresh()
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func int(_ key: String) -> Int64 { Int64(status[key] ?? "") ?? 0 }

    func refresh() {
        status = readStatus()
        let state = status["state"] ?? "importing"
        let total = int("total_files"), doneFiles = int("done_files"), failed = int("failed")
        let totalBytes = int("total_bytes")
        var doneBytes = int("done_bytes")

        let dest = status["dest"] ?? NSHomeDirectory() + "/Pictures/GoogleGlass"
        photosDest.stringValue = "Photos → \(tildePath(dest))"
        videosDest.stringValue = "Videos → \(tildePath(status["dest_movies"] ?? dest + "/Movies"))"

        switch state {
        case "importing":
            // adb writes straight into the destination file, so its size is the live progress of the current file.
            if let current = status["current_local"], !current.isEmpty {
                doneBytes += min(fileSize(current), int("current_size"))
            }
            headline.stringValue = "Importing from Google Glass…"
            let name = status["current_file"] ?? ""
            detail.stringValue = "Copying \(min(doneFiles + 1, total)) of \(total)" + (name.isEmpty ? "" : " · \(name)")
            bar.doubleValue = totalBytes > 0 ? Double(doneBytes) / Double(totalBytes) : 0

            var amountText = "\(bytes(doneBytes)) of \(bytes(totalBytes))"
            let elapsed = Date().timeIntervalSince1970 - Double(int("started"))
            if elapsed > 3, doneBytes > 0 {
                let remaining = Double(totalBytes - doneBytes) / (Double(doneBytes) / elapsed)
                amountText += " · about \(duration(remaining)) left"
            }
            amounts.stringValue = amountText
            hint.stringValue = "Keep Glass plugged in until this finishes."
            hint.isHidden = false
            closeButton.title = "Hide"

        case "disconnected":
            finish(headline: "Glass was unplugged",
                   detail: "Copied \(doneFiles) of \(total) files. Reconnect Glass to import the rest.",
                   symbol: "exclamationmark.triangle", tint: .systemOrange, progress: doneBytes, of: totalBytes)

        default: // done
            let summary = failed > 0
                ? "\(doneFiles) of \(total) files saved. \(failed) couldn't be copied and are still on Glass."
                : "\(doneFiles) \(doneFiles == 1 ? "file" : "files") saved (\(bytes(doneBytes)))."
            finish(headline: failed > 0 ? "Import finished with problems" : "Import complete",
                   detail: summary,
                   symbol: failed > 0 ? "exclamationmark.triangle" : "checkmark.circle",
                   tint: failed > 0 ? .systemOrange : .systemGreen, progress: doneBytes, of: totalBytes)
        }
    }

    func finish(headline text: String, detail info: String, symbol: String, tint: NSColor,
                progress: Int64, of total: Int64) {
        headline.stringValue = text
        detail.stringValue = info
        detail.lineBreakMode = .byWordWrapping
        detail.maximumNumberOfLines = 2
        bar.doubleValue = total > 0 ? Double(progress) / Double(total) : 1
        amounts.stringValue = "\(bytes(progress)) of \(bytes(total))"
        hint.isHidden = true
        icon.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        icon.contentTintColor = tint
        closeButton.title = "Done"

        // Bring the window back once at the end, even if it was hidden during the import.
        if !finished {
            finished = true
            if hiddenByUser {
                panel.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc func showInFinder() {
        let current = status["current_local"] ?? ""
        if !current.isEmpty, FileManager.default.fileExists(atPath: current) {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: current)])
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: status["dest"] ?? NSHomeDirectory() + "/Pictures/GoogleGlass"))
        }
    }

    @objc func closeOrHide() {
        if finished {
            NSApp.terminate(nil)
        } else {
            hiddenByUser = true
            panel.orderOut(nil)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeOrHide()
        return false
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = ProgressController()
app.run()
