// Original app mark using the four-tile motif selected after checking Tabler apps.
import AppKit
import Foundation
let root = URL(fileURLWithPath: CommandLine.arguments[1])
func icon(_ size: Int, to url: URL) throws {
  let image = NSImage(size: NSSize(width:size,height:size))
  image.lockFocus()
  NSColor(red:0.08,green:0.27,blue:0.25,alpha:1).setFill()
  NSBezierPath(rect:NSRect(x:0,y:0,width:size,height:size)).fill()
  let s=CGFloat(size)
  for (x,y) in [(0.24,0.24),(0.54,0.24),(0.24,0.54),(0.54,0.54)] {
    NSColor(red:0.91,green:0.95,blue:0.88,alpha:1).setFill()
    NSBezierPath(roundedRect:NSRect(x:s*x,y:s*y,width:s*0.22,height:s*0.22),xRadius:s*0.04,yRadius:s*0.04).fill()
  }
  image.unlockFocus()
  let data=NSBitmapImageRep(data:image.tiffRepresentation!)!.representation(using:.png,properties:[:])!
  try FileManager.default.createDirectory(at:url.deletingLastPathComponent(),withIntermediateDirectories:true)
  try data.write(to:url)
}
for (density,size) in [("mdpi",48),("hdpi",72),("xhdpi",96),("xxhdpi",144),("xxxhdpi",192)] {
  try icon(size,to:root.appendingPathComponent("apps/mobile/android/app/src/main/res/mipmap-\(density)/ic_launcher.png"))
}
let assets=root.appendingPathComponent("apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset")
let manifest=try JSONSerialization.jsonObject(with:Data(contentsOf:assets.appendingPathComponent("Contents.json"))) as! [String:Any]
for entry in manifest["images"] as! [[String:Any]] {
  guard let file=entry["filename"] as? String,let size=entry["size"] as? String,let scale=entry["scale"] as? String else { continue }
  let pixels=Double(size.split(separator:"x")[0])! * Double(scale.dropLast())!
  try icon(Int(pixels),to:assets.appendingPathComponent(file))
}
