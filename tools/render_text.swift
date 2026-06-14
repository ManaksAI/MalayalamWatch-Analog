// Render a single shaped text string to a tightly-cropped transparent PNG using
// CoreText (proper Malayalam shaping: conjuncts + vowel reordering).
//
// Usage: swift render_text.swift <fontPath> <size> <inkHex> <wght> <out.png> <text>
//   inkHex e.g. 111111 ; wght e.g. 600 (variable-font weight axis)
import Foundation
import CoreText
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let a = CommandLine.arguments
guard a.count == 7 else { FileHandle.standardError.write("bad args\n".data(using: .utf8)!); exit(2) }
let fontPath = a[1]
let size = CGFloat(Double(a[2])!)
let inkHex = UInt32(a[3], radix: 16)!
let wght = Double(a[4])!
let outPath = a[5]
let text = a[6]

let url = URL(fileURLWithPath: fontPath) as CFURL
CTFontManagerRegisterFontsForURL(url, .process, nil)
let descs = CTFontManagerCreateFontDescriptorsFromURL(url) as! [CTFontDescriptor]
// apply the weight variation axis ('wght' = 0x77676874)
let varDesc = CTFontDescriptorCreateCopyWithAttributes(
    descs[0],
    [kCTFontVariationAttribute: [0x77676874: wght]] as CFDictionary)
let font = CTFontCreateWithFontDescriptor(varDesc, size, nil)

let r = CGFloat((inkHex >> 16) & 0xff) / 255.0
let g = CGFloat((inkHex >> 8) & 0xff) / 255.0
let b = CGFloat(inkHex & 0xff) / 255.0
let ink = CGColor(red: r, green: g, blue: b, alpha: 1)

let astr = NSAttributedString(string: text, attributes: [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): ink])
let line = CTLineCreateWithAttributedString(astr)

let cs = CGColorSpaceCreateDeviceRGB()
let info = CGImageAlphaInfo.premultipliedLast.rawValue
let scratch = CGContext(data: nil, width: 8, height: 8, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs, bitmapInfo: info)!
let ib = CTLineGetImageBounds(line, scratch)
let pad: CGFloat = 4
let w = Int(ceil(ib.width) + 2 * pad)
let h = Int(ceil(ib.height) + 2 * pad)

let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                    bytesPerRow: 0, space: cs, bitmapInfo: info)!
ctx.setShouldAntialias(true)
ctx.setAllowsAntialiasing(true)
ctx.textPosition = CGPoint(x: pad - ib.minX, y: pad - ib.minY)
CTLineDraw(line, ctx)

let img = ctx.makeImage()!
let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: outPath) as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("\(text) -> \(w)x\(h)")
