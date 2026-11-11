import Foundation
import CoreImage
import AppKit

// usage: hue <in.png> <out.png> <radians|gray>
let a = CommandLine.arguments
guard a.count == 4, let img = CIImage(contentsOf: URL(fileURLWithPath: a[1])) else { exit(1) }
let f: CIFilter
if a[3] == "gray" {
  f = CIFilter(name: "CIColorControls")!
  f.setValue(img, forKey: kCIInputImageKey)
  f.setValue(0.0, forKey: kCIInputSaturationKey)
} else {
  f = CIFilter(name: "CIHueAdjust")!
  f.setValue(img, forKey: kCIInputImageKey)
  f.setValue(Double(a[3]) ?? 0, forKey: kCIInputAngleKey)
}
let ctx = CIContext()
let out = f.outputImage!
let rep = NSBitmapImageRep(ciImage: out)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
