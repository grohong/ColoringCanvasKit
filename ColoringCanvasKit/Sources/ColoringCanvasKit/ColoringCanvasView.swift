//
//  ColoringCanvasView.swift
//
//
//  Created by Hong Seong Ho on 8/11/24.
//

import UIKit
import ColoringModule

public protocol ColoringCanvasViewDelegate: AnyObject {

    func backwardEnabled(isEnabled: Bool)
    func forwardEnabled(isEnabled: Bool)
}

public final class ColoringCanvasView: UIImageView {

    public weak var delegate: ColoringCanvasViewDelegate?

    public var brushSize: Double = 50
    public var colorMode: ToolKind = .autograph {
        didSet {
            lastPoint = nil
            brushMoved = false
        }
    }

    private var colorR: Int32 = .zero
    private var colorG: Int32 = .zero
    private var colorB: Int32 = .zero
    private var lastRenderTime: TimeInterval = .zero

    // 메모리 이슈로 back, forward 앞뒤로 5장씩만 저장
    private let imagesLimit = 5
    private var savedImages = [UIImage]() {
        didSet { updateBackwardForwardStatus() }
    }

    private var currentIndex = 0 {
        didSet { updateBackwardForwardStatus() }
    }

    private var lastPoint: CGPoint?
    private var brushMoved = false
    private var imageDropped = false

    private (set) var fgImage: UIImage?
    private (set) var bgImage: UIImage?

    private var isImageChanged: Bool { (currentIndex != 0 || imageDropped) }

    public func updateImage(canvasImage: CanvasImage) {
        guard let originImage = UIImage(data: canvasImage.originImage),
              let pixelBuffer = originImage.pixelBuffer else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }

        let ptr = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0)
        let width = Int32(CVPixelBufferGetWidthOfPlane(pixelBuffer, 0))
        let height = Int32(CVPixelBufferGetHeightOfPlane(pixelBuffer, 0))
        let bytesPerRow = Int32(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0))

        savedImages.removeAll()
        currentIndex = 0
        let newImages = Coloring.setImage(
            ptr,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            threshold: 128
        ) as Array

        if let bgData = canvasImage.bgImage,
           let bg = UIImage(data: bgData) {
            bgImage = bg
            fgImage = newImages[safe: 1] as? UIImage
            if let fg = fgImage, let mergedImage = bg.mergeWith(topImage: fg) {
                self.image = mergedImage
                savedImages.append(mergedImage)
            }
        } else {
            bgImage = newImages.first as? UIImage
            fgImage = newImages[safe: 1] as? UIImage
            if let bg = bgImage, let fg = fgImage, let mergedImage = bg.mergeWith(topImage: fg) {
                self.image = mergedImage
                savedImages.append(mergedImage)
            }
        }
    }

    public func updateColor(from color: UIColor) {
        var red: CGFloat = .zero
        var green: CGFloat = .zero
        var blue: CGFloat = .zero
        var alpha: CGFloat = .zero

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        colorR = Int32(red * 255)
        colorG = Int32(green * 255)
        colorB = Int32(blue * 255)
    }

    public func back() {
        guard currentIndex > 0, let fg = fgImage, let previousImage = savedImages[safe: currentIndex - 1] else { return }
        let mergedImage = previousImage.mergeWith(topImage: fg)
        self.image = mergedImage
        bgImage = previousImage
        currentIndex -= 1
    }

    public func forward() {
        guard let fg = fgImage, let nextImage = savedImages[safe: currentIndex + 1] else { return }
        let mergedImage = nextImage.mergeWith(topImage: fg)
        self.image = mergedImage
        bgImage = nextImage
        currentIndex += 1
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.image != nil,
              event?.touches(for: self)?.count == 1,
              let firstTouch = touches.first else { return }

        brushMoved = false
        let coalescedTouches = event?.coalescedTouches(for: firstTouch)
        lastPoint = getScaledPoints(with: coalescedTouches).first
        switch colorMode {
        case .fill:
            break
        default:
            if let scaledPoint = lastPoint {
                Coloring.makeMask(scaledPoint)
            }
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard event?.touches(for: self)?.count == 1,
              let firstTouch = touches.first else { return }

        switch colorMode {
        case .fill:
            break
        default:
            let scaledPoints = getScaledPoints(with: event?.coalescedTouches(for: firstTouch))
            for scaledPoint in scaledPoints {
                Coloring.update(scaledPoint)
            }

            lastPoint = scaledPoints.last

            if brushMoved {
                let now = Date().timeIntervalSince1970
                let fps = 1.0 / 30.0
                guard fps <= now - lastRenderTime else { return }
                lastRenderTime = now
            }

            if self.image != nil {
                updateMove(save: false)
                brushMoved = true
            }
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            lastPoint = nil
            brushMoved = false
            Coloring.touchEnded()
        }

        switch colorMode {
        case .fill:
            break
        default:
            guard brushMoved else { break }

            if let scaledPoint = lastPoint {
                Coloring.update(scaledPoint)
            }

            updateMove(save: true)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        defer {
            lastPoint = nil
            brushMoved = false
            Coloring.touchEnded()
        }

        switch colorMode {
        case .fill:
            if let point = lastPoint, let newImage = Coloring.fill(point, r: colorR, g: colorG, b: colorB) {
                addBackgroundImage(newImage, save: true)
            }
        default:
            guard brushMoved else { break }

            if let scaledPoint = lastPoint {
                Coloring.update(scaledPoint)
            }

            updateMove(save: true)
        }
    }
}

private extension ColoringCanvasView {

    func updateMove(save: Bool) {
        guard self.image != nil else { return }

        var newImage: UIImage?
        switch colorMode {
        case .eraser:
            newImage = Coloring.erase(brushSize)
        case .crayon:
            newImage = Coloring.drawCrayon(brushSize, r: colorR, g: colorG, b: colorB)
        case .autograph:
            newImage = Coloring.drawLine(brushSize, r: colorR, g: colorG, b: colorB)
        case .brush:
            newImage = Coloring.drawBrush(brushSize, r: colorR, g: colorG, b: colorB)
        case .fill:
            break
        }

        if let bg = newImage { addBackgroundImage(bg, save: save) }
    }

    func addBackgroundImage(_ image: UIImage, save: Bool) {
        if let bg = bgImage,
           let fg = fgImage,
           let mergedBg = bg.mergeWith(topImage: image),
           let mergedImage = mergedBg.mergeWith(topImage: fg) {
            self.image = mergedImage
            if save {
                bgImage = mergedBg
                addSavedImage(mergedBg)
            }
        }
    }

    func getScaledPoints(with touches: [UITouch]?) -> [CGPoint] {
        guard let image = self.image else { return [] }

        var scaledPoints: [CGPoint] = []
        for touch in touches ?? [] {
            let point = touch.location(in: self)
            let imageSize = image.size
            let parentSize = bounds.size
            let scaledPoint = point.changeScale(to: imageSize, parentScreenSize: parentSize)
            if scaledPoint.x < 0 || scaledPoint.y < 0 { continue }
            if scaledPoint.x > imageSize.width || scaledPoint.y > imageSize.height { continue }
            scaledPoints.append(scaledPoint)
        }

        return scaledPoints
    }

    func addSavedImage(_ image: UIImage) {
        let index = currentIndex + 1
        if savedImages.count > index {
            let forwardImagesCount = savedImages.count - index
            savedImages.removeSubrange(index..<index+forwardImagesCount)
        }

        savedImages.append(image)
        currentIndex += 1
        if currentIndex > imagesLimit {
            imageDropped = true
            currentIndex -= 1
            savedImages.removeFirst()
        }

        if currentIndex + imagesLimit <= savedImages.count {
            savedImages.removeLast()
        }
    }

    func updateBackwardForwardStatus() {
        if currentIndex >= savedImages.count - 1 {
            delegate?.forwardEnabled(isEnabled: false)
        } else {
            delegate?.forwardEnabled(isEnabled: true)
        }

        if currentIndex == 0 {
            delegate?.backwardEnabled(isEnabled: false)
        } else {
            delegate?.backwardEnabled(isEnabled: true)
        }
    }
}
