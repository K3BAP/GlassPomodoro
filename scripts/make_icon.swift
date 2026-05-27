#!/usr/bin/env swift
// Generates a 1024x1024 master PNG for the app icon and renders all the sizes
// the AppIcon.appiconset needs, writing them next to its Contents.json.
//
// Usage: swift scripts/make_icon.swift
//
// The art: a Liquid-Glass-style rounded square with a warm tomato gradient,
// a frosted-glass timer ring showing a focus arc, a tick at 12 o'clock, and a
// small green leaf — a Pomodoro timer at a glance.

import AppKit
import CoreGraphics

let size = 1024
let scale = CGFloat(size) / 1024.0

guard let ctx = CGContext(
    data: nil,
    width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("could not create context") }

func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }
func L(_ v: CGFloat) -> CGFloat { v * scale }

let space = CGColorSpaceCreateDeviceRGB()

// Background rounded square (macOS-style margin around a 1024 canvas).
let margin: CGFloat = 100
let bgRect = CGRect(x: L(margin), y: L(margin), width: L(1024 - 2 * margin), height: L(1024 - 2 * margin))
let corner = L(220)
let bgPath = CGPath(roundedRect: bgRect, cornerWidth: corner, cornerHeight: corner, transform: nil)

ctx.saveGState()
ctx.addPath(bgPath)
ctx.clip()
let bgGradient = CGGradient(colorsSpace: space, colors: [
    CGColor(red: 1.00, green: 0.45, blue: 0.38, alpha: 1.0),
    CGColor(red: 0.86, green: 0.20, blue: 0.16, alpha: 1.0),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bgGradient,
    start: CGPoint(x: bgRect.midX, y: bgRect.maxY),
    end: CGPoint(x: bgRect.midX, y: bgRect.minY),
    options: [])

// Soft top glass highlight.
ctx.saveGState()
let hi = CGGradient(colorsSpace: space, colors: [
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.28),
    CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(hi,
    start: CGPoint(x: bgRect.midX, y: bgRect.maxY),
    end: CGPoint(x: bgRect.midX, y: bgRect.midY + L(60)),
    options: [])
ctx.restoreGState()
ctx.restoreGState()

let center = CGPoint(x: L(512), y: L(500))
let ringRadius = L(248)
let ringWidth = L(74)

// Frosted track of the timer ring.
ctx.setLineWidth(ringWidth)
ctx.setLineCap(.round)
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.30))
ctx.addArc(center: center, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
ctx.strokePath()

// Focus-progress arc (~70%), bright white, starting at 12 o'clock going clockwise.
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.96))
let start = CGFloat.pi / 2
let sweep = CGFloat.pi * 2 * 0.70
ctx.addArc(center: center, radius: ringRadius, startAngle: start, endAngle: start - sweep, clockwise: true)
ctx.strokePath()

// Center hub + a single hand pointing up-right.
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.96))
ctx.fillEllipse(in: CGRect(x: center.x - L(26), y: center.y - L(26), width: L(52), height: L(52)))
ctx.setLineWidth(L(34))
ctx.setLineCap(.round)
ctx.move(to: center)
ctx.addLine(to: CGPoint(x: center.x + L(96), y: center.y + L(120)))
ctx.strokePath()

// Green leaf above the ring (the tomato stem).
ctx.saveGState()
let leafCenter = CGPoint(x: L(512), y: L(500) + ringRadius + L(36))
let leaf = CGMutablePath()
leaf.move(to: CGPoint(x: leafCenter.x, y: leafCenter.y - L(46)))
leaf.addQuadCurve(to: CGPoint(x: leafCenter.x, y: leafCenter.y + L(52)),
                  control: CGPoint(x: leafCenter.x + L(78), y: leafCenter.y))
leaf.addQuadCurve(to: CGPoint(x: leafCenter.x, y: leafCenter.y - L(46)),
                  control: CGPoint(x: leafCenter.x - L(78), y: leafCenter.y))
ctx.addPath(leaf)
ctx.setFillColor(CGColor(red: 0.30, green: 0.74, blue: 0.36, alpha: 1.0))
ctx.fillPath()
ctx.restoreGState()

// Write master PNG.
let scriptDir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()
let iconset = repoRoot.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset")
let masterURL = iconset.appendingPathComponent("icon_1024.png")

let cgImage = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: cgImage)
let pngData = rep.representation(using: .png, properties: [:])!
try! pngData.write(to: masterURL)
print("wrote \(masterURL.path)")
