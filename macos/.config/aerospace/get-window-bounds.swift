import CoreGraphics
import Foundation

guard CommandLine.arguments.count > 1,
      let targetWid = UInt32(CommandLine.arguments[1]) else {
    exit(1)
}

let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
    exit(1)
}

for window in windowList {
    guard let wid = window["kCGWindowNumber"] as? UInt32, wid == targetWid,
          let bounds = window["kCGWindowBounds"] as? [String: Any],
          let w = bounds["Width"] as? CGFloat,
          let h = bounds["Height"] as? CGFloat else { continue }
    print("\(Int(w)) \(Int(h))")
    exit(0)
}
exit(1)
