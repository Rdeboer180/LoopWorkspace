// CUSTOM (rdeboer180): generator for the pre-meal toolbar icons in
// OverrideAssetsLoop.xcassets (plate + down arrow, replacing the plate + timer
// dial so it no longer reads as a second carb button). Same 40x40 pt canvas,
// fork and knife proportions as Loop's Meal.pdf so the toolbar stays a family.
//
// Regenerate from the workspace root:
//   swift tests/make-premeal-icons.swift OverrideAssetsLoop.xcassets
//
// Revert: delete OverrideAssetsLoop.xcassets/Pre-Meal.imageset and
// "Pre-Meal Selected.imageset"; Loop's own icons then apply again.

import CoreGraphics
import Foundation

let size = CGSize(width: 40, height: 40)

/// All shapes in top-left coordinates. Each is one closed, non-self-intersecting
/// outline (the plate is two concentric circles), so even-odd filling gives:
/// fork, knife, plate rim and arrow solid; the plate's interior empty.
func glyph() -> CGPath {
    let p = CGMutablePath()

    // Fork: three tines, bowl, handle with a rounded end.
    p.move(to: CGPoint(x: 3.6, y: 6))
    for (l, r) in [(3.6, 4.6), (5.6, 6.6), (7.6, 8.6)] {
        if l != 3.6 { p.addLine(to: CGPoint(x: l, y: 12)); p.addLine(to: CGPoint(x: l, y: 6)) }
        p.addLine(to: CGPoint(x: r, y: 6))
        if r != 8.6 { p.addLine(to: CGPoint(x: r, y: 12)) }
    }
    p.addLine(to: CGPoint(x: 8.6, y: 15))
    p.addQuadCurve(to: CGPoint(x: 7.2, y: 18), control: CGPoint(x: 8.6, y: 17.2))
    p.addLine(to: CGPoint(x: 7.2, y: 32.9))
    p.addArc(center: CGPoint(x: 6.1, y: 32.9), radius: 1.1, startAngle: 0, endAngle: .pi, clockwise: false)
    p.addLine(to: CGPoint(x: 5.0, y: 18))
    p.addQuadCurve(to: CGPoint(x: 3.6, y: 15), control: CGPoint(x: 3.6, y: 17.2))
    p.closeSubpath()

    // Knife: straight spine on the right, curved blade on the left.
    p.move(to: CGPoint(x: 36.2, y: 6))
    p.addQuadCurve(to: CGPoint(x: 36.6, y: 7.4), control: CGPoint(x: 36.6, y: 6.2))
    p.addLine(to: CGPoint(x: 36.6, y: 32.9))
    p.addArc(center: CGPoint(x: 35.5, y: 32.9), radius: 1.1, startAngle: 0, endAngle: .pi, clockwise: false)
    p.addLine(to: CGPoint(x: 34.4, y: 21))
    p.addLine(to: CGPoint(x: 33.0, y: 20))
    p.addQuadCurve(to: CGPoint(x: 36.2, y: 6), control: CGPoint(x: 32.6, y: 9.5))
    p.closeSubpath()

    // Plate rim: same centre and outer size as the carbs plate.
    let c = CGPoint(x: 20, y: 20.5)
    p.addEllipse(in: CGRect(x: c.x - 11.2, y: c.y - 11.2, width: 22.4, height: 22.4))
    p.addEllipse(in: CGRect(x: c.x - 9.0, y: c.y - 9.0, width: 18.0, height: 18.0))

    // Down arrow inside the plate: "lower the target before eating".
    p.move(to: CGPoint(x: 18.85, y: 13.4))
    p.addLine(to: CGPoint(x: 21.15, y: 13.4))
    p.addLine(to: CGPoint(x: 21.15, y: 20.6))
    p.addLine(to: CGPoint(x: 24.5, y: 20.6))
    p.addLine(to: CGPoint(x: 20.0, y: 27.0))
    p.addLine(to: CGPoint(x: 15.5, y: 20.6))
    p.addLine(to: CGPoint(x: 18.85, y: 20.6))
    p.closeSubpath()
    return p
}

func writePDF(_ url: URL, selected: Bool) {
    var box = CGRect(origin: .zero, size: size)
    guard let ctx = CGContext(url as CFURL, mediaBox: &box, nil) else { fatalError("cannot create \(url.path)") }
    ctx.beginPDFPage(nil)
    ctx.translateBy(x: 0, y: size.height)   // top-left coordinates
    ctx.scaleBy(x: 1, y: -1)
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    if selected {
        // Filled rounded tile with the glyph knocked out (transparent), matching
        // the style of Loop's "Pre-Meal Selected" asset. Rect + glyph under the
        // even-odd rule leaves the glyph's solid parts as holes.
        let tile = CGMutablePath()
        tile.addPath(CGPath(roundedRect: CGRect(x: 0.5, y: 0.5, width: 39, height: 39), cornerWidth: 6, cornerHeight: 6, transform: nil))
        tile.addPath(glyph())
        ctx.addPath(tile)
    } else {
        ctx.addPath(glyph())
    }
    ctx.fillPath(using: .evenOdd)
    ctx.endPDFPage()
    ctx.closePDF()
}

func writeImageSet(root: URL, name: String, file: String, selected: Bool) throws {
    let dir = root.appendingPathComponent("\(name).imageset")
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    writePDF(dir.appendingPathComponent(file), selected: selected)
    // Same Contents.json shape as Loop's own Pre-Meal assets, plus an explicit
    // template intent so the toolbar tint (carb green) always applies.
    let json = """
    {
      "images" : [
        {
          "filename" : "\(file)",
          "idiom" : "universal"
        }
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      },
      "properties" : {
        "preserves-vector-representation" : true,
        "template-rendering-intent" : "template"
      }
    }

    """
    try json.write(to: dir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "OverrideAssetsLoop.xcassets")
try writeImageSet(root: root, name: "Pre-Meal", file: "Pre-Meal.pdf", selected: false)
try writeImageSet(root: root, name: "Pre-Meal Selected", file: "Pre-Meal Selected.pdf", selected: true)
print("wrote Pre-Meal and Pre-Meal Selected to \(root.path)")
