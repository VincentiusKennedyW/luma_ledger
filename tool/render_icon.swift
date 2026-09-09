import AppKit

// The SVG in assets/luma-mark.svg is the editable source for this geometric mark.
let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : FileManager.default.currentDirectoryPath)
func drawIcon(_ size: Int, _ path: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: CGFloat(size)/1024, y: CGFloat(size)/1024)
    NSColor(srgbRed: 23/255, green: 63/255, blue: 53/255, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
    NSColor(srgbRed: 217/255, green: 235/255, blue: 207/255, alpha: 1).setFill()
    for (x,height) in [(256.0,240.0),(448.0,400.0),(640.0,560.0)] {
        NSBezierPath(roundedRect: NSRect(x:x,y:232,width:128,height:height),xRadius:64,yRadius:64).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: path)
}
for folder in ["ios/Runner/Assets.xcassets/AppIcon.appiconset", "macos/Runner/Assets.xcassets/AppIcon.appiconset"] {
    let directory=root.appendingPathComponent(folder)
    let json=try JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("Contents.json"))) as! [String:Any]
    for image in json["images"] as! [[String:String]] {
        guard let file=image["filename"],let rawSize=image["size"],let rawScale=image["scale"] else { continue }
        let size=Double(rawSize.components(separatedBy:"x")[0])! * Double(rawScale.replacingOccurrences(of:"x",with:""))!
        try drawIcon(Int(size),directory.appendingPathComponent(file))
    }
}
for (folder,size) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
    try drawIcon(size,root.appendingPathComponent("android/app/src/main/res/mipmap-\(folder)/ic_launcher.png"))
}
try drawIcon(1024,root.appendingPathComponent("assets/luma-icon.png"))
