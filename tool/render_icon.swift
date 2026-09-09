import Foundation

// Resize the generated master; never redraw the retired three-bar mark.
// Run from the project root: swift tool/render_icon.swift
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
let sourceURL = root.appendingPathComponent("assets/branding/luma-icon-master.png")
guard FileManager.default.fileExists(atPath: sourceURL.path) else {
    fatalError("Missing icon master at \(sourceURL.path)")
}
func writeIcon(_ size: Int, _ path: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = ["--resampleHeightWidth", String(size), String(size), sourceURL.path, "--out", path.path]
    process.standardOutput = FileHandle.nullDevice
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        fatalError("Icon export failed: \(path.path)")
    }
}
for folder in ["ios/Runner/Assets.xcassets/AppIcon.appiconset", "macos/Runner/Assets.xcassets/AppIcon.appiconset"] {
    let directory = root.appendingPathComponent(folder)
    let json = try JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("Contents.json"))) as! [String: Any]
    for image in json["images"] as! [[String: String]] {
        guard let file = image["filename"], let rawSize = image["size"], let rawScale = image["scale"] else { continue }
        let size = Double(rawSize.components(separatedBy: "x")[0])! * Double(rawScale.replacingOccurrences(of: "x", with: ""))!
        try writeIcon(Int(size), directory.appendingPathComponent(file))
    }
}
for (folder, size) in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)] {
    try writeIcon(size, root.appendingPathComponent("android/app/src/main/res/mipmap-\(folder)/ic_launcher.png"))
}
try writeIcon(1024, root.appendingPathComponent("assets/luma-icon.png"))
